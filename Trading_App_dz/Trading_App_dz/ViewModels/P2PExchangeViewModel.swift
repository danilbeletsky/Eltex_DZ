import Combine
import Foundation

protocol P2PExchangeRepository {
    func loadCurrencies(completion: @escaping (Result<[String], NetworkServiceError>) -> Void)
    func loadCurrenciesPublisher() -> AnyPublisher<[String], NetworkServiceError>
    func loadOffers(for pair: CurrencyPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void)
    func performExchange(
        offer: P2POffer,
        amount: Double,
        wallet: Wallet,
        completion: @escaping (Result<Void, NetworkServiceError>) -> Void
    )
}

final class NetworkP2PExchangeRepository: P2PExchangeRepository {
    private let networkService: NetworkService

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }

    func loadCurrencies(completion: @escaping (Result<[String], NetworkServiceError>) -> Void) {
        networkService.loadCurrencies(completion: completion)
    }

    func loadCurrenciesPublisher() -> AnyPublisher<[String], NetworkServiceError> {
        networkService.loadCurrenciesPublisher()
    }

    func loadOffers(for pair: CurrencyPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void) {
        networkService.loadOffers(for: pair, completion: completion)
    }

    func performExchange(
        offer: P2POffer,
        amount: Double,
        wallet: Wallet,
        completion: @escaping (Result<Void, NetworkServiceError>) -> Void
    ) {
        networkService.performExchange(
            offer: offer,
            amount: amount,
            wallet: wallet,
            completion: completion
        )
    }
}

final class P2PExchangeViewModel {
    enum ViewState {
        case idle
        case loading
        case loaded
        case failed(NetworkServiceError)
    }

    struct State {
        var currentPair: CurrencyPair
        var offers: [P2POffer]
        var apiCurrencies: [String]
        var statusText: String
        var statusIsError: Bool
        var fromBalance: Double
        var toBalance: Double
        var viewState: ViewState
    }

    private(set) var state = State(
        currentPair: CurrencyPair(from: "USD", to: "BTC"),
        offers: [],
        apiCurrencies: [],
        statusText: "",
        statusIsError: false,
        fromBalance: 0,
        toBalance: 0,
        viewState: .idle
    )

    let wallet: Wallet

    var onStateUpdated: ((State) -> Void)?
    var onError: ((NetworkServiceError) -> Void)?
    var onExchangeSuccess: (() -> Void)?

    private let repository: P2PExchangeRepository
    private var cancellables = Set<AnyCancellable>()
    private var offersTimeoutWorkItem: DispatchWorkItem?
    private var activeOffersRequestID = UUID()
    private let offersTimeout: TimeInterval = 8

    init(
        repository: P2PExchangeRepository = NetworkP2PExchangeRepository(),
        wallet: Wallet = Wallet(
            initialBalances: [
                "USD": 20_000,
                "BTC": 1.4,
                "EUR": 12_000,
                "USDT": 30_000,
                "ETH": 22
            ]
        )
    ) {
        self.repository = repository
        self.wallet = wallet
    }

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
        let requestID = UUID()
        activeOffersRequestID = requestID

        offersTimeoutWorkItem?.cancel()
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            guard let self, self.activeOffersRequestID == requestID else { return }
            self.state.offers = []
            self.state.statusText = NetworkServiceError.timeout.userMessage
            self.state.statusIsError = true
            self.state.viewState = .failed(.timeout)
            self.onError?(.timeout)
            self.emit()
        }
        offersTimeoutWorkItem = timeoutWorkItem

        state.statusText = "Загрузка предложений..."
        state.statusIsError = false
        state.viewState = .loading
        emit()
        DispatchQueue.main.asyncAfter(deadline: .now() + offersTimeout, execute: timeoutWorkItem)

        repository.loadOffers(for: state.currentPair) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                guard self.activeOffersRequestID == requestID else { return }
                self.offersTimeoutWorkItem?.cancel()
                self.offersTimeoutWorkItem = nil

                switch result {
                case .success(let offers):
                    self.state.offers = offers
                    self.state.statusText = "Найдено продавцов: \(offers.count)"
                    self.state.statusIsError = false
                    self.state.viewState = .loaded
                case .failure(let error):
                    self.state.offers = []
                    self.state.statusText = error.userMessage
                    self.state.statusIsError = true
                    self.state.viewState = .failed(error)
                    self.onError?(error)
                }
                self.emit()
            }
        }
    }

    func executeExchange(offer: P2POffer, amount: Double) {
        repository.performExchange(offer: offer, amount: amount, wallet: wallet) { [weak self] result in
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
            repository.loadCurrenciesPublisher()
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
            repository.loadCurrencies { [weak self] result in
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
