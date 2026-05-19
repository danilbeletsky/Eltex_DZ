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

protocol P2PExchangeGateway: AnyObject {
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

extension NetworkService: P2PExchangeGateway {}

nonisolated final class NetworkP2PExchangeRepository: P2PExchangeRepository {
    private let networkService: P2PExchangeGateway

    init(networkService: P2PExchangeGateway = NetworkService()) {
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

nonisolated final class P2PExchangeViewModel {
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
        AppLogger.p2p(
            "P2P-экран: начальная загрузка",
            level: .info,
            metadata: ["pair": "\(state.currentPair.from)/\(state.currentPair.to)"]
        )
        updateBalances()
        loadApiCurrencies()
        loadOffers()
    }

    func selectPair(_ pair: CurrencyPair) {
        AppLogger.p2p(
            "Смена валютной пары",
            level: .info,
            metadata: ["pair": "\(pair.from)/\(pair.to)"]
        )
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
            AppLogger.p2p(
                "Таймаут загрузки предложений",
                level: .error,
                metadata: [
                    "pair": "\(self.state.currentPair.from)/\(self.state.currentPair.to)",
                    "timeoutSec": "\(self.offersTimeout)"
                ]
            )
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
                guard self.activeOffersRequestID == requestID else {
                    AppLogger.p2p("Ответ по предложениям устарел, игнорируем", level: .debug)
                    return
                }
                self.offersTimeoutWorkItem?.cancel()
                self.offersTimeoutWorkItem = nil

                switch result {
                case .success(let offers):
                    AppLogger.p2p(
                        "Предложения загружены",
                        level: .info,
                        metadata: ["count": "\(offers.count)"]
                    )
                    self.state.offers = offers
                    self.state.statusText = "Найдено продавцов: \(offers.count)"
                    self.state.statusIsError = false
                    self.state.viewState = .loaded
                case .failure(let error):
                    AppLogger.p2p(
                        "Ошибка загрузки предложений",
                        level: .error,
                        metadata: ["error": error.logDescription]
                    )
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
        AppLogger.p2p(
            "Запуск обмена",
            level: .info,
            metadata: [
                "seller": offer.sellerName,
                "amount": "\(amount)",
                "pair": "\(offer.pair.from)/\(offer.pair.to)"
            ]
        )
        repository.performExchange(offer: offer, amount: amount, wallet: wallet) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    AppLogger.p2p("Обмен успешно завершён", level: .info, metadata: ["seller": offer.sellerName])
                    self.updateBalances()
                    self.loadOffers()
                    self.onExchangeSuccess?()
                case .failure(let error):
                    AppLogger.p2p(
                        "Ошибка обмена",
                        level: .error,
                        metadata: ["error": error.logDescription, "seller": offer.sellerName]
                    )
                    self.onError?(error)
                }
            }
        }
    }

    private func loadApiCurrencies() {
        if NetworkService.isNetworkWithCombine {
            AppLogger.p2p("Загрузка валют API (Combine)", level: .info)
            repository.loadCurrenciesPublisher()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            AppLogger.p2p(
                                "Ошибка загрузки валют API (Combine)",
                                level: .error,
                                metadata: ["error": error.logDescription]
                            )
                        }
                    },
                    receiveValue: { [weak self] currencies in
                        AppLogger.p2p(
                            "Валюты API получены (Combine)",
                            level: .info,
                            metadata: ["count": "\(currencies.count)"]
                        )
                        self?.state.apiCurrencies = currencies
                        self?.emit()
                    }
                )
                .store(in: &cancellables)
        } else {
            AppLogger.p2p("Загрузка валют API (completion)", level: .info)
            repository.loadCurrencies { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    switch result {
                    case .success(let currencies):
                        AppLogger.p2p(
                            "Валюты API получены",
                            level: .info,
                            metadata: ["count": "\(currencies.count)"]
                        )
                        self.state.apiCurrencies = currencies
                        self.emit()
                    case .failure(let error):
                        AppLogger.p2p(
                            "Ошибка загрузки валют API",
                            level: .error,
                            metadata: ["error": error.logDescription]
                        )
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
