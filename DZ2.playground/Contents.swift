import UIKit
import Foundation

extension Double {
    var asCurrency: String {
        return String(format: "%.2f", self)
    }
}

extension String {
    var capitalizedFirst: String {
        return prefix(1).uppercased() + dropFirst()
    }
}

private protocol BotProtocol {
    var name: String { get set }
    mutating func returnName()
}

protocol MoneyProtocol {
    var balance: Double { get }
    var currency: String { get }
    var formattedBalance: String { get }
    
    func startTrading()
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
        return "\(balance.asCurrency) \(currency)"
    }
    
    var formattedPrice: String {
        return "\(price.asCurrency) \(currency)"
    }
    
    var profitLoss: Double? {
        guard isPositionOpen else { return nil }
        return price - buyPrice
    }
    
    var profitLossPercentage: Double? {
        guard let pl = profitLoss, buyPrice > 0 else { return nil }
        return (pl / buyPrice) * 100
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
    
    func startTrading() {
        generateRandomCurrency()
        print("\nНачало торгов")
        print(formattedBalance)
        
        for _ in 0..<10 {
            performTradeCycle()
        }
        
        print("\nИтог")
        print(formattedBalance)
    }
    
    func generateRandomCurrency() {
        let currencyList = ["USD", "EUR", "RUB", "BTC", "ETH"]
        self.currency = currencyList.randomElement() ?? "RUB"
    }
    
    func generateRandomPrice() {
        self.price = Double.random(in: 1000...50000)
    }
    
    private func performTradeCycle() {
        generateRandomPrice()
        print("\n\(formattedPrice)")
        
        if !isPositionOpen {
            handleClosedPosition()
        } else {
            handleOpenPosition()
        }
    }
    
    private func handleClosedPosition() {
        choice = Choice.allCases.randomElement() ?? .ignore
        
        switch choice {
        case .ignore:
            transactionIgnore()
        case .purchase:
            transactionBuy()
        case .sale:
            print("Нет позиции для продажи")
        }
    }
    
    private func handleOpenPosition() {
        print("\(positionStatus)")
        
        if let pl = profitLoss {
            print("Текущий Доход/Убыток: \(pl.asCurrency)")
        }
        
        choice = Choice.allCases.randomElement() ?? .ignore
        
        switch choice {
        case .sale:
            transactionSell()
        case .purchase:
            print("Уже есть открытая позиция")
        case .ignore:
            print("Держу позицию")
        }
    }
    
    private func transactionIgnore() {
        print("\(choice.description.capitalizedFirst)")
    }
    
    private func transactionBuy() {
        buyPrice = price
        isPositionOpen = true
        print("\(choice.description.capitalizedFirst) по \(price.asCurrency)")
    }
    
    private func transactionSell() {
        let sellPrice = price
        let income = sellPrice - buyPrice
        balance += income
        
        print("\(choice.description.capitalizedFirst) по \(price.asCurrency)")
        print("FROM: \(buyPrice.asCurrency) → TO: \(sellPrice.asCurrency)")
        print("ДОХОД: \(income.asCurrency)")
        print("\(formattedBalance)")
        
        isPositionOpen = false
    }
}

struct Bot: BotProtocol {
    private let nameList = ["Bob", "Nikita", "Danil", "Alice", "Barmaldak"]
    var name = String()
    
    var greeting: String {
        return "Вас приветствует \(name) бот"
    }
    
    mutating func returnName() {
        self.name = nameList.randomElement() ?? "GPT"
        print(greeting)
    }
}

var bot = Bot()
bot.returnName()

let money = Money(balance: 20000)
money.startTrading()
