import Foundation

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

private extension Money {
    
    func performTradeCycle() -> [String] {
        var logs: [String] = []
        
        generateRandomPrice()
        logs.append("\n\(formattedPrice)")
        
        if !isPositionOpen {
            logs.append(contentsOf: handleClosedPosition())
        } else {
            logs.append(contentsOf: handleOpenPosition())
        }
        
        return logs
    }
    
    func handleClosedPosition() -> [String] {
        var logs: [String] = []
        choice = Choice.allCases.randomElement() ?? .ignore
        
        switch choice {
        case .ignore:
            logs.append(choice.description.capitalizedFirst)
        case .purchase:
            buyPrice = price
            isPositionOpen = true
            logs.append("\(choice.description.capitalizedFirst) по \(price.asCurrency)")
        case .sale:
            logs.append("Нет позиции для продажи")
        }
        
        return logs
    }
    
    func handleOpenPosition() -> [String] {
        var logs: [String] = []
        logs.append(positionStatus)
        
        if let pl = profitLoss {
            logs.append("Доход/Убыток: \(pl.asCurrency)")
        }
        
        choice = Choice.allCases.randomElement() ?? .ignore
        
        switch choice {
        case .sale:
            let sellPrice = price
            let income = sellPrice - buyPrice
            balance += income
            
            logs.append("\(choice.description.capitalizedFirst) по \(price.asCurrency)")
            logs.append("FROM: \(buyPrice.asCurrency) → TO: \(sellPrice.asCurrency)")
            logs.append("ДОХОД: \(income.asCurrency)")
            logs.append(formattedBalance)
            
            isPositionOpen = false
            
        case .purchase:
            logs.append("Уже есть открытая позиция")
        case .ignore:
            logs.append("Держу позицию")
        }
        
        return logs
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
    
    func startTrading() -> [String]
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
    
    func startTrading() -> [String] {
        var allLogs: [String] = []
        
        generateRandomCurrency()
        allLogs.append("\nНачало торгов")
        allLogs.append(formattedBalance)
        
        for _ in 0..<10 {
            allLogs.append(contentsOf: performTradeCycle())
        }
        
        allLogs.append("\nИтог")
        allLogs.append(formattedBalance)
        
        return allLogs
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

