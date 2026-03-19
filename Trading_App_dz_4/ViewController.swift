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
    
    var onUpdate: ((String) -> Void)?
    
    private func log(_ text: String) {
        onUpdate?(text)
    }
    
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
        log("\nНачало торгов")
        log(formattedBalance)
        
        for _ in 0..<10 {
            performTradeCycle()
        }
        
        log("\nИтог")
        log(formattedBalance)
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
        log("\n\(formattedPrice)")
        
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
            log(choice.description.capitalizedFirst)
        case .purchase:
            buyPrice = price
            isPositionOpen = true
            log("\(choice.description.capitalizedFirst) по \(price.asCurrency)")
        case .sale:
            log("Нет позиции для продажи")
        }
    }
    
    private func handleOpenPosition() {
        log(positionStatus)
        
        if let pl = profitLoss {
            log("Доход/Убыток: \(pl.asCurrency)")
        }
        
        choice = Choice.allCases.randomElement() ?? .ignore
        
        switch choice {
        case .sale:
            let sellPrice = price
            let income = sellPrice - buyPrice
            balance += income
            
            log("\(choice.description.capitalizedFirst) по \(price.asCurrency)")
            log("FROM: \(buyPrice.asCurrency) → TO: \(sellPrice.asCurrency)")
            log("ДОХОД: \(income.asCurrency)")
            log(formattedBalance)
            
            isPositionOpen = false
            
        case .purchase:
            log("Уже есть открытая позиция")
        case .ignore:
            log("Держу позицию")
        }
    }
}

struct Bot: BotProtocol {
    private let nameList = ["Bob", "Nikita", "Danil", "Alice", "Barmaldak"]
    
    var onUpdate: ((String) -> Void)?
    
    var name = String()
    
    var greeting: String {
        return "Вас приветствует \(name) бот"
    }
    
    mutating func returnName() {
        self.name = nameList.randomElement() ?? "GPT"
        onUpdate?(greeting)
    }
}

final class ViewController: UIViewController {

    let containerView = UIView()
    let filterStack = UIStackView()
    let onlineSwitch = UISwitch()
    let runButton = UIButton(type: .system)
    let outputTextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupContainer()
        setupFilter()
        setupButton()
        setupOutput()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutUI()
    }
    
    func setupContainer() {
        containerView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        view.addSubview(containerView)
    }
    
    func setupFilter() {
        filterStack.axis = .horizontal
        filterStack.spacing = 10
        filterStack.distribution = .equalSpacing
        
        let label = UILabel()
        label.text = "Онлайн торговля"
        
        filterStack.addArrangedSubview(label)
        filterStack.addArrangedSubview(onlineSwitch)
        
        containerView.addSubview(filterStack)
    }
    
    
    func setupButton() {
        runButton.setTitle("RUN", for: .normal)
        runButton.backgroundColor = .systemGreen
        runButton.setTitleColor(.black, for: .normal)
        runButton.layer.cornerRadius = 12
        
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
        
        containerView.addSubview(runButton)
    }
    
    func setupOutput() {
        outputTextView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        outputTextView.font = UIFont.systemFont(ofSize: 16)
        outputTextView.isEditable = false
        
        view.addSubview(outputTextView)
    }
    
    func layoutUI() {
        let safe = view.safeAreaInsets
        
        containerView.frame = CGRect(
            x: 20,
            y: safe.top + 20,
            width: view.frame.width - 40,
            height: view.frame.height * 0.25
        )
        
        filterStack.frame = CGRect(
            x: 10,
            y: 20,
            width: containerView.frame.width - 20,
            height: 40
        )
        
        runButton.frame = CGRect(
            x: 20,
            y: 100,
            width: containerView.frame.width - 40,
            height: 50
        )
        
        outputTextView.frame = CGRect(
            x: 20,
            y: containerView.frame.maxY + 20,
            width: view.frame.width - 40,
            height: view.frame.height - containerView.frame.maxY - 40
        )
    }
    
    @objc func runTapped() {
        outputTextView.text = ""
        
        func append(_ text: String) {
            DispatchQueue.main.async {
                self.outputTextView.text += text + "\n"
                let range = NSRange(location: self.outputTextView.text.count - 1, length: 0)
                self.outputTextView.scrollRangeToVisible(range)
            }
        }
        
        var bot = Bot()
        bot.onUpdate = append
        bot.returnName()
        
        let money = Money(balance: 20000)
        money.onUpdate = append
        
        DispatchQueue.global().async {
            money.startTrading()
        }
    }
}
