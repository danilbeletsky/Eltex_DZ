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
    case purchase
    case sale
    case ignore
    
    var color: UIColor {
        switch self {
        case .purchase:
            return .green
        case .sale:
            return .red
        case .ignore:
            return .yellow
        }
    }
    
    var description: String {
        switch self {
        case .purchase:
            return "Покупка"
        case .sale:
            return "Продажа"
        case .ignore:
            return "Игнор"
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
        return "\(type.description) по \(price.asCurrency) \(currency)"
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
}

private protocol BotProtocol {
    var name: String { get set }
    func makeName() -> String
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
            case .purchase:
                return "покупка"
            case .sale:
                return "продажа"
            case .ignore:
                return "игнор"
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
        return "\(balance.asCurrency) \(currency)"
    }
    
    var formattedPrice: String {
        return "\(price.asCurrency) \(currency)"
    }
    
    var profitLoss: Double? {
        guard isPositionOpen else { return nil }
        return price - buyPrice
    }
    
    var positionStatus: String {
        return isPositionOpen ? "Открыта (куплено по \(buyPrice.asCurrency))" : "Закрыта"
    }
    
    init(balance: Double) {
        self.balance = balance
        self.price = Double.random(in: 1000...50000)
        self.currency = "RUB"
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
        var trades: [Trade] = []
        
        generateRandomPrice()
        
        if !isPositionOpen {
            trades.append(contentsOf: handleClosedPosition())
        } else {
            trades.append(contentsOf: handleOpenPosition())
        }
        return trades
    }
    
    private func handleClosedPosition() -> [Trade] {
        var trades: [Trade] = []
        choice = Choice.allCases.randomElement() ?? .ignore
        
        switch choice {
        case .ignore:
            let trade = Trade(
                type: .ignore,
                price: price,
                currency: currency,
                balance: nil,
                profitLoss: nil,
                isPositionOpen: false,
                buyPrice: nil
            )
            trades.append(trade)
            
        case .purchase:
            buyPrice = price
            isPositionOpen = true
            let trade = Trade(
                type: .purchase,
                price: price,
                currency: currency,
                balance: balance,
                profitLoss: nil,
                isPositionOpen: true,
                buyPrice: buyPrice
            )
            trades.append(trade)
            
        case .sale:
            let trade = Trade(
                type: .ignore,
                price: price,
                currency: currency,
                balance: nil,
                profitLoss: nil,
                isPositionOpen: false,
                buyPrice: nil
            )
            trades.append(trade)
        }
        return trades
    }
    
    private func handleOpenPosition() -> [Trade] {
        var trades: [Trade] = []
        
        choice = Choice.allCases.randomElement() ?? .ignore
        
        switch choice {
        case .sale:
            let sellPrice = price
            let income = sellPrice - buyPrice
            balance += income
            
            let trade = Trade(
                type: .sale,
                price: price,
                currency: currency,
                balance: balance,
                profitLoss: income,
                isPositionOpen: false,
                buyPrice: buyPrice
            )
            trades.append(trade)
            isPositionOpen = false
            
        case .purchase:
            let trade = Trade(
                type: .ignore,
                price: price,
                currency: currency,
                balance: nil,
                profitLoss: nil,
                isPositionOpen: true,
                buyPrice: buyPrice
            )
            trades.append(trade)
            
        case .ignore:
            let trade = Trade(
                type: .ignore,
                price: price,
                currency: currency,
                balance: nil,
                profitLoss: profitLoss,
                isPositionOpen: true,
                buyPrice: buyPrice
            )
            trades.append(trade)
        }
        return trades
    }
    
    func generateRandomCurrency() {
        let currencyList = ["USD", "EUR", "RUB", "BTC", "ETH"]
        self.currency = currencyList.randomElement() ?? "RUB"
    }
    
    func generateRandomPrice() {
        self.price = Double.random(in: 1000...50000)
    }
}

struct Bot: BotProtocol {
    private let nameList = ["Bob", "Nikita", "Danil", "Alice", "Barmaldak"]
    
    var name = String()
    
    var greeting: String {
        return "Вас приветствует \(name) бот"
    }
    
    func makeName() -> String {
        return nameList.randomElement() ?? "GPT"
    }
    
    func sendGreeting() -> String {
        return greeting
    }
}
