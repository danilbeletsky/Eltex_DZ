import Foundation

enum NetworkServiceError: Error {
    case noInternet
    case parsingFailed
    case forbidden
    case operationFailed

    var userMessage: String {
        switch self {
        case .noInternet:
            return "Нет подключения к интернету. Проверьте сеть и попробуйте снова."
        case .parsingFailed:
            return "Что-то пошло не так, попробуйте позже."
        case .forbidden:
            return "У вас нет прав на просмотр данного раздела."
        case .operationFailed:
            return "Операция не удалась. Попробуйте снова."
        }
    }
}

struct P2POffer {
    let id = UUID()
    let sellerName: String
    let pair: CurrencyPair
    let rate: Double
    let reserve: Double
}

final class NetworkService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRates(
        baseCurrency: String,
        completion: @escaping (Result<[String: Double], NetworkServiceError>) -> Void
    ) {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/\(baseCurrency)") else {
            completion(.failure(.operationFailed))
            return
        }

        session.dataTask(with: url) { data, response, error in
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                completion(.failure(.noInternet))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, (400...499).contains(httpResponse.statusCode) {
                completion(.failure(.forbidden))
                return
            }

            guard let data else {
                completion(.failure(.operationFailed))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ExchangeRatesResponse.self, from: data)
                completion(.success(decoded.rates))
            } catch {
                completion(.failure(.parsingFailed))
            }
        }.resume()
    }

    func makeOffers(
        for pair: CurrencyPair,
        rates: [String: Double],
        count: Int = 10
    ) -> [P2POffer] {
        guard let baseRate = rates[pair.to], baseRate > 0 else { return [] }

        let sellers = [
            "RapidMarket", "CryptoDeal", "FiatBridge", "AtlasPay", "NorthEx",
            "SwiftSwap", "MercuryTrade", "P2P Point", "BlueShift", "SmartChange"
        ]

        var offers: [P2POffer] = []
        for index in 0..<count {
            let slippage = Double.random(in: 0.005...0.08)
            let sellerRate = baseRate * (1 - slippage)
            let reserve = Double.random(in: 300...15_000)
            offers.append(
                P2POffer(
                    sellerName: sellers[index % sellers.count],
                    pair: pair,
                    rate: sellerRate,
                    reserve: reserve
                )
            )
        }

        return offers.sorted { $0.rate > $1.rate }
    }

    func performExchange(
        offer: P2POffer,
        amount: Double,
        wallet: Wallet,
        completion: @escaping (Result<Void, NetworkServiceError>) -> Void
    ) {
        if Bool.random() {
            wallet.executeOperation(
                from: offer.pair.from,
                to: offer.pair.to,
                amount: amount,
                rate: offer.rate
            )
            completion(.success(()))
            return
        }

        performFailedRequest(completion: completion)
    }

    private func performFailedRequest(
        completion: @escaping (Result<Void, NetworkServiceError>) -> Void
    ) {
        guard let url = URL(string: "https://httpstat.us/403") else {
            completion(.failure(.operationFailed))
            return
        }

        session.dataTask(with: url) { _, response, error in
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                completion(.failure(.noInternet))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, (400...499).contains(httpResponse.statusCode) {
                completion(.failure(.forbidden))
                return
            }

            completion(.failure(.operationFailed))
        }.resume()
    }
}

private struct ExchangeRatesResponse: Decodable {
    let rates: [String: Double]
}
