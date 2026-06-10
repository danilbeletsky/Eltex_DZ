import Combine
import Foundation
import UIKit

private extension Double {
    var asCurrency: String {
        return String(format: "%.2f", self)
    }
}

private extension String {
    var capitalizedFirst: String {
        return prefix(1).uppercased() + dropFirst()
    }
}

enum TradeType {
    case profit
    case loss
    case info

    var color: UIColor {
        switch self {
        case .profit:
            return .systemGreen
        case .loss:
            return .systemRed
        case .info:
            return .systemYellow
        }
    }
}

struct Trade {
    let id = UUID()
    let type: TradeType
    let message: String
    let details: String?

    var mainInfo: String { message }
    var additionalInfo: String? { details }
}

struct TradingConfig {
    static let minOperationsPerDay = 2
    static let maxOperationsPerDay = 8
    static let workDays = 30
    static let minTradeAmount: Double = 5
    static let maxTradeAmount: Double = 40
    static let topUpAmount: Double = 1_000
}

nonisolated(unsafe) final class Wallet {
    private var balances: [String: Double]
    private var credit: [String: Double] = [:]
    private let queue = DispatchQueue(label: "wallet.queue.concurrent", attributes: .concurrent)

    init(initialBalances: [String: Double]) {
        self.balances = initialBalances
    }

    func balance(for currency: String) -> Double {
        queue.sync { balances[currency, default: 0] }
    }

    func snapshot() -> [String: Double] {
        queue.sync { balances }
    }

    func creditSnapshot() -> [String: Double] {
        queue.sync { credit }
    }

    func executeOperation(from: String, to: String, amount: Double, rate: Double) {
        queue.sync(flags: .barrier) {
            ensurePositiveBalance(for: from)
            ensurePositiveBalance(for: to)

            let fromBalance = balances[from, default: 0]
            let spendAmount = min(fromBalance, amount)
            guard spendAmount > 0 else { return }

            balances[from, default: 0] -= spendAmount
            balances[to, default: 0] += spendAmount * rate

            ensurePositiveBalance(for: from)
            ensurePositiveBalance(for: to)
        }
    }

    private func ensurePositiveBalance(for currency: String) {
        let current = balances[currency, default: 0]
        guard current <= 0 else { return }
        balances[currency, default: 0] += TradingConfig.topUpAmount
        credit[currency, default: 0] += TradingConfig.topUpAmount
    }
}

struct TradingBot {
    let name: String
    let pair: CurrencyPair
}

struct BotDayResult {
    let botName: String
    let pair: CurrencyPair
    let day: Int
    let startBalance: Double
    let endBalance: Double

    var income: Double { endBalance - startBalance }
}

enum BotRunner {
    static func run(
        bots: [TradingBot],
        wallet: Wallet,
        completion: @escaping ([Trade]) -> Void
    ) {
        let workerQueue = DispatchQueue.global(qos: .userInitiated)
        let writeQueue = DispatchQueue(label: "bot.results.write")
        let group = DispatchGroup()
        var dailyResults: [BotDayResult] = []

        for day in 1...TradingConfig.workDays {
            for bot in bots {
                group.enter()
                workerQueue.async {
                    let start = wallet.balance(for: bot.pair.to)
                    let operations = Int.random(in: TradingConfig.minOperationsPerDay...TradingConfig.maxOperationsPerDay)

                    for _ in 0..<operations {
                        let amount = Double.random(in: TradingConfig.minTradeAmount...TradingConfig.maxTradeAmount)
                        let rate = Double.random(in: 0.5...1.6)
                        wallet.executeOperation(from: bot.pair.from, to: bot.pair.to, amount: amount, rate: rate)
                    }

                    let end = wallet.balance(for: bot.pair.to)
                    let result = BotDayResult(
                        botName: bot.name,
                        pair: bot.pair,
                        day: day,
                        startBalance: start,
                        endBalance: end
                    )

                    writeQueue.async {
                        dailyResults.append(result)
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: workerQueue) {
            let sorted = dailyResults.sorted {
                if $0.day == $1.day { return $0.botName < $1.botName }
                return $0.day < $1.day
            }

            let trades = sorted.map { result -> Trade in
                let sign = result.income >= 0 ? "+" : ""
                let message = "\(result.botName) (\(result.pair.from)-\(result.pair.to)), day = \(result.day), income = \(sign)\(result.income.asCurrency)"
                let detail = "Start: \(result.startBalance.asCurrency) \(result.pair.to)\nEnd: \(result.endBalance.asCurrency) \(result.pair.to)"
                let type: TradeType = result.income >= 0 ? .profit : .loss
                return Trade(type: type, message: message, details: detail)
            }

            completion(trades)
        }
    }
}

enum NetworkServiceError: Error {
    case noInternet
    case timeout
    case parsing
    case forbiddenSection
    case server(Int)
    case unknown

    var userMessage: String {
        switch self {
        case .noInternet:
            return "Отсутствует подключение к интернету."
        case .timeout:
            return "Сервер отвечает слишком долго. Попробуйте снова."
        case .parsing:
            return "Что-то пошло не так, попробуйте позже."
        case .forbiddenSection:
            return "У вас нет прав на просмотр данного раздела."
        case .server(let code):
            return "Ошибка сервера: \(code)."
        case .unknown:
            return "Операция не удалась. Попробуйте снова."
        }
    }
}

struct P2POffer {
    let sellerName: String
    let pair: CurrencyPair
    let rate: Double
    let reserve: Double
}

nonisolated(unsafe) final class NetworkService {

    /// `false` — загрузка валют через completion (как раньше), `true` — через Combine (`loadCurrenciesPublisher()`).
    static var isNetworkWithCombine = false

    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadCurrencies(completion: @escaping (Result<[String], NetworkServiceError>) -> Void) {
        AppLogger.network("Загрузка списка валют", level: .info, metadata: ["base": "USD"])
        loadRateMap(base: "USD") { result in
            switch result {
            case .success(let map):
                let currencies = map.keys.sorted()
                AppLogger.network(
                    "Список валют получен",
                    level: .info,
                    metadata: ["count": "\(currencies.count)"]
                )
                completion(.success(currencies))
            case .failure(let error):
                AppLogger.networkFailure(url: "exchange-rates?currency=USD", error: error)
                completion(.failure(error))
            }
        }
    }

    /// Загрузка списка валют через Combine pipeline (ответ Coinbase разбирается в цепочке).
    func loadCurrenciesPublisher() -> AnyPublisher<[String], NetworkServiceError> {
        loadRateMapPublisher(base: "USD")
            .map { $0.keys.sorted() }
            .eraseToAnyPublisher()
    }

    func loadOffers(for pair: CurrencyPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void) {
        AppLogger.network(
            "Загрузка P2P-предложений",
            level: .info,
            metadata: ["pair": "\(pair.from)/\(pair.to)"]
        )
        loadRateMap(base: pair.from) { result in
            switch result {
            case .success(let rates):
                guard let rawRate = rates[pair.to], rawRate > 0 else {
                    AppLogger.network(
                        "Курс для пары не найден или некорректен",
                        level: .error,
                        metadata: ["pair": "\(pair.from)/\(pair.to)"]
                    )
                    completion(.failure(.parsing))
                    return
                }

                let sellers = [
                    "TraderFox", "CryptoBridge", "FastEx", "BlueLedger",
                    "SatoshiDesk", "SafeP2P", "GlobalSwap", "PrimeDesk"
                ]
                let offers = sellers.map { seller -> P2POffer in
                    let discount = Double.random(in: 0.003...0.055)
                    let adjustedRate = rawRate * (1 - discount)
                    return P2POffer(
                        sellerName: seller,
                        pair: pair,
                        rate: adjustedRate,
                        reserve: Double.random(in: 150...30_000)
                    )
                }
                .sorted { $0.rate > $1.rate }

                AppLogger.network(
                    "P2P-предложения сформированы",
                    level: .info,
                    metadata: ["count": "\(offers.count)", "pair": "\(pair.from)/\(pair.to)"]
                )
                completion(.success(offers))
            case .failure(let error):
                AppLogger.networkFailure(
                    url: "exchange-rates?currency=\(pair.from)",
                    error: error
                )
                completion(.failure(error))
            }
        }
    }

    func performExchange(
        offer: P2POffer,
        amount: Double,
        wallet: Wallet,
        completion: @escaping (Result<Void, NetworkServiceError>) -> Void
    ) {
        guard amount > 0 else {
            AppLogger.network(
                "Обмен отклонён: некорректная сумма",
                level: .error,
                metadata: ["amount": "\(amount)"]
            )
            completion(.failure(.unknown))
            return
        }

        AppLogger.network(
            "Запрос на P2P-обмен",
            level: .info,
            metadata: [
                "seller": offer.sellerName,
                "pair": "\(offer.pair.from)/\(offer.pair.to)",
                "amount": "\(amount)"
            ]
        )

        if Bool.random() {
            wallet.executeOperation(from: offer.pair.from, to: offer.pair.to, amount: amount, rate: offer.rate)
            AppLogger.network("P2P-обмен выполнен локально (успех)", level: .info)
            completion(.success(()))
            return
        }

        guard let url = URL(string: "https://httpstat.us/403") else {
            AppLogger.network("Некорректный URL для имитации ошибки обмена", level: .error)
            completion(.failure(.unknown))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("amount=\(amount)".utf8)
        AppLogger.networkRequest(method: "POST", url: url.absoluteString, bodySize: request.httpBody?.count)

        let startedAt = Date()
        let task = session.dataTask(with: request) { _, response, error in
            let durationMs = Int(Date().timeIntervalSince(startedAt) * 1000)
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            AppLogger.networkResponse(
                url: url.absoluteString,
                statusCode: statusCode,
                durationMs: durationMs,
                dataSize: nil
            )

            if let mapped = self.mapError(error: error, response: response) {
                AppLogger.networkFailure(url: url.absoluteString, error: mapped, underlying: error)
                completion(.failure(mapped))
            } else {
                AppLogger.network("Неизвестная ошибка при обмене", level: .error)
                completion(.failure(.unknown))
            }
        }
        task.resume()
    }
}

private extension NetworkService {
    struct ExchangeRatesResponse: Decodable {
        let rates: [String: Double]
    }

    static func networkError(from urlError: URLError) -> NetworkServiceError {
        if urlError.code == .notConnectedToInternet {
            return .noInternet
        }
        if urlError.code == .timedOut {
            return .timeout
        }
        return .unknown
    }

    func decodedRateMap(data: Data, response: URLResponse?) -> Result<[String: Double], NetworkServiceError> {
        if let mapped = mapError(error: nil, response: response) {
            return .failure(mapped)
        }
        do {
            let payload = try decoder.decode(CoinbaseResponse.self, from: data)
            let rates = payload.data.rates.compactMapValues { Double($0) }
            if rates.isEmpty {
                AppLogger.network("Пустой словарь курсов после декодирования", level: .error)
                return .failure(.parsing)
            }
            return .success(rates)
        } catch {
            AppLogger.network(
                "Ошибка JSON-декодирования курсов",
                level: .error,
                metadata: ["details": error.localizedDescription]
            )
            return .failure(.parsing)
        }
    }

    func loadRateMapPublisher(base: String) -> AnyPublisher<[String: Double], NetworkServiceError> {
        guard let url = URL(string: "https://api.coinbase.com/v2/exchange-rates?currency=\(base)") else {
            AppLogger.network("Некорректный URL (Combine) курсов валют", level: .error, metadata: ["base": base])
            return Fail(error: NetworkServiceError.unknown).eraseToAnyPublisher()
        }
        AppLogger.networkRequest(method: "GET", url: url.absoluteString, metadata: ["pipeline": "combine"])
        return session.dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.global(qos: .utility))
            .mapError { error -> NetworkServiceError in
                let mapped = Self.networkError(from: error)
                AppLogger.networkFailure(url: url.absoluteString, error: mapped, underlying: error)
                return mapped
            }
            .flatMap { [weak self] data, response -> AnyPublisher<[String: Double], NetworkServiceError> in
                guard let self else {
                    AppLogger.network("Сервис освобождён до обработки ответа (Combine)", level: .error)
                    return Fail(error: NetworkServiceError.unknown).eraseToAnyPublisher()
                }
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                AppLogger.networkResponse(
                    url: url.absoluteString,
                    statusCode: statusCode,
                    durationMs: nil,
                    dataSize: data.count
                )
                switch self.decodedRateMap(data: data, response: response) {
                case .success(let rates):
                    AppLogger.network(
                        "Курсы валют декодированы (Combine)",
                        level: .info,
                        metadata: ["base": base, "ratesCount": "\(rates.count)"]
                    )
                    return Just(rates)
                        .setFailureType(to: NetworkServiceError.self)
                        .eraseToAnyPublisher()
                case .failure(let error):
                    AppLogger.networkFailure(url: url.absoluteString, error: error)
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func loadRateMap(base: String, completion: @escaping (Result<[String: Double], NetworkServiceError>) -> Void) {
        guard let url = URL(string: "https://api.coinbase.com/v2/exchange-rates?currency=\(base)") else {
            AppLogger.network("Некорректный URL курсов валют", level: .error, metadata: ["base": base])
            completion(.failure(.unknown))
            return
        }

        AppLogger.networkRequest(method: "GET", url: url.absoluteString)
        let startedAt = Date()

        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }

            let durationMs = Int(Date().timeIntervalSince(startedAt) * 1000)
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            AppLogger.networkResponse(
                url: url.absoluteString,
                statusCode: statusCode,
                durationMs: durationMs,
                dataSize: data?.count
            )

            if let mapped = self.mapError(error: error, response: response) {
                AppLogger.networkFailure(url: url.absoluteString, error: mapped, underlying: error)
                completion(.failure(mapped))
                return
            }

            guard let data else {
                AppLogger.network("Пустое тело ответа курсов валют", level: .error, metadata: ["base": base])
                completion(.failure(.unknown))
                return
            }

            let decodeResult = self.decodedRateMap(data: data, response: response)
            switch decodeResult {
            case .success(let rates):
                AppLogger.network(
                    "Курсы валют декодированы",
                    level: .info,
                    metadata: ["base": base, "ratesCount": "\(rates.count)"]
                )
            case .failure(let error):
                AppLogger.networkFailure(url: url.absoluteString, error: error)
            }
            completion(decodeResult)
        }
        task.resume()
    }

    func mapError(error: Error?, response: URLResponse?) -> NetworkServiceError? {
        if let urlError = error as? URLError {
            if urlError.code == .notConnectedToInternet {
                return .noInternet
            }
            if urlError.code == .timedOut {
                return .timeout
            }
        }

        if let httpResponse = response as? HTTPURLResponse {
            if (400...499).contains(httpResponse.statusCode) {
                return .forbiddenSection
            }
            if httpResponse.statusCode >= 500 {
                return .server(httpResponse.statusCode)
            }
        }

        if error != nil {
            return .unknown
        }
        return nil
    }
}

private struct CoinbaseResponse: Decodable {
    let data: CoinbaseRatesContainer
}

private struct CoinbaseRatesContainer: Decodable {
    let rates: [String: String]
}
