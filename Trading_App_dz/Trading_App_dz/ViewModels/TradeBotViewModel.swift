import Foundation

final class TradeBotViewModel {
    struct State {
        var currentPair: CurrencyPair
        var trades: [Trade]
        var greetingText: String
        var isRunning: Bool
    }

    private let defaultPair = CurrencyPair(from: "USD", to: "BTC")
    private let allCurrencies = [
        "USD", "BTC", "ETH", "EUR", "RUB", "USDT", "GBP", "JPY", "CNY", "AED"
    ]

    private(set) var state = State(
        currentPair: CurrencyPair(from: "USD", to: "BTC"),
        trades: [],
        greetingText: "",
        isRunning: false
    )

    let wallet = Wallet(
        initialBalances: [
            "USD": 20_000,
            "BTC": 2_000,
            "RUB": 600_000,
            "ETH": 1_500
        ]
    )

    var onStateUpdated: ((State) -> Void)?

    func viewDidLoad() {
        emit()
    }

    func runBots() {
        guard !state.isRunning else { return }
        state.isRunning = true
        state.greetingText = "Запускаю ботов в параллельных потоках..."
        emit()

        let bots = makeBots()
        BotRunner.run(bots: bots, wallet: wallet) { [weak self] generatedTrades in
            DispatchQueue.main.async {
                guard let self else { return }
                self.state.trades = generatedTrades
                self.state.greetingText = "Выполнено: \(bots.count) ботов, \(TradingConfig.workDays) дней."
                self.state.isRunning = false
                self.emit()
            }
        }
    }

    func reset() {
        state.currentPair = defaultPair
        state.trades = []
        state.greetingText = ""
        emit()
    }

    func randomizePair() {
        guard allCurrencies.count >= 2 else { return }
        let from = allCurrencies.randomElement() ?? "USD"
        var to = allCurrencies.randomElement() ?? "BTC"
        while to == from {
            to = allCurrencies.randomElement() ?? "BTC"
        }
        state.currentPair = CurrencyPair(from: from, to: to)
        state.trades = []
        state.greetingText = ""
        emit()
    }

    func updatePair(_ pair: CurrencyPair) {
        state.currentPair = pair
        state.trades = []
        state.greetingText = ""
        emit()
    }

    private func makeBots() -> [TradingBot] {
        let selectedPairBots: [TradingBot] = [
            TradingBot(name: "Bot\(state.currentPair.from)\(state.currentPair.to)Alpha", pair: state.currentPair),
            TradingBot(name: "Bot\(state.currentPair.from)\(state.currentPair.to)Delta", pair: state.currentPair),
            TradingBot(name: "Bot\(state.currentPair.from)\(state.currentPair.to)Sigma", pair: state.currentPair)
        ]

        let supportPair = CurrencyPair(from: "RUB", to: "ETH")
        let supportPairBots: [TradingBot] = [
            TradingBot(name: "BotRUBETHCore", pair: supportPair),
            TradingBot(name: "BotRUBETHFlow", pair: supportPair)
        ]

        return selectedPairBots + supportPairBots
    }

    private func emit() {
        onStateUpdated?(state)
    }
}
