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

final class Wallet {
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
