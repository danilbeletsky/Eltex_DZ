import Combine
import Foundation

final class P2PExchangeViewModel {
    struct State {
        var currentPair: CurrencyPair
        var offers: [P2POffer]
        var apiCurrencies: [String]
        var statusText: String
        var statusIsError: Bool
        var fromBalance: Double
        var toBalance: Double
    }

    private(set) var state = State(
        currentPair: CurrencyPair(from: "USD", to: "BTC"),
        offers: [],
        apiCurrencies: [],
        statusText: "",
        statusIsError: false,
        fromBalance: 0,
        toBalance: 0
    )

    let wallet = Wallet(
        initialBalances: [
            "USD": 20_000,
            "BTC": 1.4,
            "EUR": 12_000,
            "USDT": 30_000,
            "ETH": 22
        ]
    )

    var onStateUpdated: ((State) -> Void)?
    var onError: ((NetworkServiceError) -> Void)?
    var onExchangeSuccess: (() -> Void)?

    private let networkService = NetworkService()
    private var cancellables = Set<AnyCancellable>()

    func viewDidLoad() {
        updateBalances()
        loadApiCurrencies()
        loadOffers()
    }

    func selectPair(_ pair: CurrencyPair) {
        state.currentPair = pair
        updateBalances()
        loadOffers()
    }

    func loadOffers() {
        state.statusText = "Загрузка предложений..."
        state.statusIsError = false
        emit()

        networkService.loadOffers(for: state.currentPair) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let offers):
                    self.state.offers = offers
                    self.state.statusText = "Найдено продавцов: \(offers.count)"
                    self.state.statusIsError = false
                case .failure(let error):
                    self.state.offers = []
                    self.state.statusText = error.userMessage
                    self.state.statusIsError = true
                    self.onError?(error)
                }
                self.emit()
            }
        }
    }

    func executeExchange(offer: P2POffer, amount: Double) {
        networkService.performExchange(offer: offer, amount: amount, wallet: wallet) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.updateBalances()
                    self.loadOffers()
                    self.onExchangeSuccess?()
                case .failure(let error):
                    self.onError?(error)
                }
            }
        }
    }

    private func loadApiCurrencies() {
        if NetworkService.isNetworkWithCombine {
            networkService.loadCurrenciesPublisher()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] currencies in
                        self?.state.apiCurrencies = currencies
                        self?.emit()
                    }
                )
                .store(in: &cancellables)
        } else {
            networkService.loadCurrencies { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if case .success(let currencies) = result {
                        self.state.apiCurrencies = currencies
                        self.emit()
                    }
                }
            }
        }
    }

    private func updateBalances() {
        state.fromBalance = wallet.balance(for: state.currentPair.from)
        state.toBalance = wallet.balance(for: state.currentPair.to)
        emit()
    }

    private func emit() {
        onStateUpdated?(state)
    }
}
