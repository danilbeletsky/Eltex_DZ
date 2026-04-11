import Foundation
import UIKit

private extension Double {
    var asCurrency: String {
        String(format: "%.2f", self)
    }
}

enum TradeType {
    case purchase
    case sale
    case ignore

    var color: UIColor {
        switch self {
        case .purchase: return .green
        case .sale: return .red
        case .ignore: return .yellow
        }
    }

    var description: String {
        switch self {
        case .purchase: return "Покупка"
        case .sale: return "Продажа"
        case .ignore: return "Игнор"
        }
    }
}

struct Trade {
    let id = UUID()
    let type: TradeType
    let price: Double
    let currency: String
    let balance: Double?
    let profitLoss: Double?
    let isPositionOpen: Bool
    let buyPrice: Double?

    var mainInfo: String {
        "\(type.description) по \(price.asCurrency) \(currency)"
    }

    var additionalInfo: String? {
        guard type != .ignore else { return nil }

        var info = ""
        if let buyPrice = buyPrice {
            info += "Куплено по: \(buyPrice.asCurrency)\n"
        }
        if let profitLoss = profitLoss {
            info += "Прибыль/убыток: \(profitLoss.asCurrency)\n"
        }
        if let balance = balance {
            info += "Баланс: \(balance.asCurrency) \(currency)"
        }
        return info.isEmpty ? nil : info
    }

    static func make(
        type: TradeType,
        price: Double,
        currency: String,
        balance: Double? = nil,
        profitLoss: Double? = nil,
        isPositionOpen: Bool,
        buyPrice: Double? = nil
    ) -> Trade {
        Trade(
            type: type,
            price: price,
            currency: currency,
            balance: balance,
            profitLoss: profitLoss,
            isPositionOpen: isPositionOpen,
            buyPrice: buyPrice
        )
    }
}

protocol MoneyProtocol {
    var balance: Double { get }
    var currency: String { get }
    var formattedBalance: String { get }

    func startTrading() -> [Trade]
    func generateRandomCurrency()
    func generateRandomPrice()
}

final class Money: MoneyProtocol {

    private enum Choice: Int, CaseIterable {
        case purchase = 1
        case sale = 2
        case ignore = 0

        var description: String {
            switch self {
            case .purchase: return "покупка"
            case .sale: return "продажа"
            case .ignore: return "игнор"
            }
        }
    }

    private(set) var balance: Double
    private(set) var currency: String
    private(set) var isPositionOpen = false
    private(set) var buyPrice: Double = 0
    private(set) var price: Double
    private var choice: Choice

    var formattedBalance: String {
        "\(balance.asCurrency) \(currency)"
    }

    var formattedPrice: String {
        "\(price.asCurrency) \(currency)"
    }

    var profitLoss: Double? {
        guard isPositionOpen else { return nil }
        return price - buyPrice
    }

    var positionStatus: String {
        isPositionOpen ? "Открыта (куплено по \(buyPrice.asCurrency))" : "Закрыта"
    }

    init(balance: Double) {
        self.balance = balance
        self.price = Double.random(in: 1000...50000)
        self.currency = ""
        self.choice = .ignore
    }

    func startTrading() -> [Trade] {
        var allTrades: [Trade] = []
        generateRandomCurrency()
        for _ in 0..<10 {
            allTrades.append(contentsOf: performTradeCycle())
        }
        return allTrades
    }

    private func performTradeCycle() -> [Trade] {
        generateRandomPrice()
        return isPositionOpen ? handleOpenPosition() : handleClosedPosition()
    }

    private func handleClosedPosition() -> [Trade] {
        choice = Choice.allCases.randomElement() ?? .ignore

        switch choice {
        case .ignore:
            return [
                .make(type: .ignore, price: price, currency: currency, isPositionOpen: false, buyPrice: nil)
            ]
        case .purchase:
            buyPrice = price
            isPositionOpen = true
            return [
                .make(type: .purchase, price: price, currency: currency, balance: balance, isPositionOpen: true, buyPrice: buyPrice)
            ]
        case .sale:
            return [
                .make(type: .ignore, price: price, currency: currency, isPositionOpen: false, buyPrice: nil)
            ]
        }
    }

    private func handleOpenPosition() -> [Trade] {
        choice = Choice.allCases.randomElement() ?? .ignore

        switch choice {
        case .sale:
            let income = price - buyPrice
            balance += income
            let trade = Trade.make(
                type: .sale,
                price: price,
                currency: currency,
                balance: balance,
                profitLoss: income,
                isPositionOpen: false,
                buyPrice: buyPrice
            )
            isPositionOpen = false
            return [trade]

        case .purchase:
            return [
                .make(type: .ignore, price: price, currency: currency, isPositionOpen: true, buyPrice: buyPrice)
            ]

        case .ignore:
            return [
                .make(type: .ignore, price: price, currency: currency, profitLoss: profitLoss, isPositionOpen: true, buyPrice: buyPrice)
            ]
        }
    }

    func generateRandomCurrency() {
        let codes = CurrencySelectionViewController.tradingCurrencyCodes
        currency = codes.randomElement() ?? "RUB"
    }

    func generateRandomPrice() {
        price = Double.random(in: 1000...50000)
    }
}

struct Bot {
    private let nameList = ["Bob", "Nikita", "Danil", "Alice", "Barmaldak"]

    var name = ""

    var greeting: String {
        "Вас приветствует \(name) бот"
    }

    func makeName() -> String {
        nameList.randomElement() ?? "GPT"
    }

    func sendGreeting() -> String {
        greeting
    }
}
