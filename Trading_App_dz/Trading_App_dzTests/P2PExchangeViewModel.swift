import Combine
import XCTest
@testable import Trading_App_dz

final class P2PExchangeViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        NetworkService.isNetworkWithCombine = false
        cancellables.removeAll()
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - ViewModel

    func test_viewDidLoad_loading_currency_balances_and_offers() {
        let wallet = Wallet(initialBalances: ["USD": 120, "BTC": 3])
        let offer = makeOffer(seller: "Alpha")
        let mock = MockRepository(
            currenciesResult: .success(["USD", "BTC", "ETH"]),
            offersResult: .success([offer])
        )
        let vm = P2PExchangeViewModel(repository: mock, wallet: wallet)

        let ready = expectation(description: "loaded state after viewDidLoad")
        vm.onStateUpdated = { state in
            if state.statusText == "Найдено продавцов: 1" && state.apiCurrencies == ["USD", "BTC", "ETH"] {
                ready.fulfill()
            }
        }

        vm.viewDidLoad()
        wait(for: [ready], timeout: 2)

        XCTAssertEqual(vm.state.fromBalance, 120)
        XCTAssertEqual(vm.state.toBalance, 3)
        XCTAssertEqual(mock.loadCurrenciesCount, 1)
        XCTAssertEqual(mock.loadOffersCount, 1)
    }

    func test_selectPair_changes_a_pair_of_balances_and_resets_offers() {
        let wallet = Wallet(initialBalances: ["USD": 100, "BTC": 2, "EUR": 50, "ETH": 3])
        let mock = MockRepository(offersResult: .success([makeOffer(seller: "PairSwap", pair: CurrencyPair(from: "EUR", to: "ETH"))]))
        let vm = P2PExchangeViewModel(repository: mock, wallet: wallet)

        let ready = expectation(description: "offers finished")
        vm.onStateUpdated = { state in
            if state.statusText.hasPrefix("Найдено продавцов") {
                ready.fulfill()
            }
        }

        vm.selectPair(CurrencyPair(from: "EUR", to: "ETH"))
        wait(for: [ready], timeout: 2)

        XCTAssertEqual(vm.state.currentPair.from, "EUR")
        XCTAssertEqual(vm.state.currentPair.to, "ETH")
        XCTAssertEqual(vm.state.fromBalance, 50)
        XCTAssertEqual(vm.state.toBalance, 3)
        XCTAssertEqual(mock.loadOffersCount, 1)
    }

    func test_loadOffers_success_shows_the_number_of_sellers() {
        let offer = makeOffer(seller: "Seller1")
        let mock = MockRepository(offersResult: .success([offer]))
        let vm = P2PExchangeViewModel(
            repository: mock,
            wallet: Wallet(initialBalances: ["USD": 100, "BTC": 1])
        )

        let ready = expectation(description: "offers loaded")
        vm.onStateUpdated = { state in
            if state.statusText == "Найдено продавцов: 1" {
                ready.fulfill()
            }
        }

        vm.loadOffers()
        wait(for: [ready], timeout: 2)

        XCTAssertEqual(vm.state.offers.count, 1)
        XCTAssertFalse(vm.state.statusIsError)
    }

    func test_loadOffers_error_updates_state_and_calls_onError() {
        let mock = MockRepository(offersResult: .failure(.noInternet))
        let vm = P2PExchangeViewModel(
            repository: mock,
            wallet: Wallet(initialBalances: ["USD": 100, "BTC": 1])
        )

        let stateReady = expectation(description: "error state")
        let errorReady = expectation(description: "onError called")
        vm.onStateUpdated = { state in
            if state.statusIsError {
                stateReady.fulfill()
            }
        }
        vm.onError = { error in
            if case .noInternet = error {
                errorReady.fulfill()
            }
        }

        vm.loadOffers()
        wait(for: [stateReady, errorReady], timeout: 2)

        XCTAssertEqual(vm.state.statusText, NetworkServiceError.noInternet.userMessage)
        XCTAssertTrue(vm.state.offers.isEmpty)
        assertFailedState(vm.state.viewState, expected: .noInternet)
    }

    func test_loadOffers_utdated_answer_ignored() {
        let firstOffer = makeOffer(seller: "Old")
        let secondOffer = makeOffer(seller: "New")
        let mock = SequencedOffersRepository(
            responses: [
                .delayed(0.15, .success([firstOffer])),
                .immediate(.success([secondOffer]))
            ]
        )
        let vm = P2PExchangeViewModel(
            repository: mock,
            wallet: Wallet(initialBalances: ["USD": 100, "BTC": 1])
        )

        let ready = expectation(description: "newest offers are kept")
        vm.onStateUpdated = { state in
            if state.statusText == "Найдено продавцов: 1",
               state.offers.first?.sellerName == "New" {
                ready.fulfill()
            }
        }

        vm.loadOffers()
        vm.loadOffers()
        wait(for: [ready], timeout: 2)

        XCTAssertEqual(mock.loadOffersCount, 2)
        XCTAssertEqual(vm.state.offers.first?.sellerName, "New")
    }

    func test_executeExchange_success_updates_balances_and_calls_reload() {
        let wallet = Wallet(initialBalances: ["USD": 100, "BTC": 1])
        let exchangeOffer = makeOffer(seller: "Seller", rate: 0.5)
        let mock = MockRepository(
            offersResult: .success([exchangeOffer]),
            exchangeResult: .success(()),
            onPerformExchange: { offer, amount, wallet in
                wallet.executeOperation(from: offer.pair.from, to: offer.pair.to, amount: amount, rate: offer.rate)
            }
        )
        let vm = P2PExchangeViewModel(repository: mock, wallet: wallet)

        let ready = expectation(description: "exchange success")
        vm.onExchangeSuccess = { ready.fulfill() }

        vm.executeExchange(offer: exchangeOffer, amount: 20)
        wait(for: [ready], timeout: 2)

        XCTAssertEqual(mock.performExchangeCount, 1)
        XCTAssertEqual(mock.loadOffersCount, 1)
        XCTAssertEqual(vm.state.fromBalance, 80)
        XCTAssertEqual(vm.state.toBalance, 11)
    }

    func test_executeExchange_error_causes_onError() {
        let mock = MockRepository(exchangeResult: .failure(.forbiddenSection))
        let vm = P2PExchangeViewModel(
            repository: mock,
            wallet: Wallet(initialBalances: ["USD": 100, "BTC": 1])
        )
        let offer = makeOffer(seller: "Seller")

        let ready = expectation(description: "exchange error")
        vm.onError = { error in
            if case .forbiddenSection = error {
                ready.fulfill()
            }
        }

        vm.executeExchange(offer: offer, amount: 10)
        wait(for: [ready], timeout: 2)

        XCTAssertEqual(mock.performExchangeCount, 1)
    }

    func test_loadApiCurrencies_via_combine_updates_state() {
        NetworkService.isNetworkWithCombine = true
        let mock = MockRepository(
            currenciesPublisherResult: .success(["USDT", "ETH"]),
            offersResult: .success([])
        )
        let vm = P2PExchangeViewModel(
            repository: mock,
            wallet: Wallet(initialBalances: ["USD": 100, "BTC": 1])
        )

        let ready = expectation(description: "combine currencies loaded")
        var didFulfill = false
        vm.onStateUpdated = { state in
            if state.apiCurrencies == ["USDT", "ETH"], !didFulfill {
                didFulfill = true
                ready.fulfill()
            }
        }

        vm.viewDidLoad()
        wait(for: [ready], timeout: 2)

        XCTAssertEqual(mock.loadCurrenciesPublisherCount, 1)
        XCTAssertEqual(mock.loadCurrenciesCount, 0)
    }

    // MARK: - Repository + Gateway (мок NetworkService)

    func test_repository_transfers_calls_to_gateway() {
        let gateway = MockGateway()
        let repository = NetworkP2PExchangeRepository(networkService: gateway)

        var currencies: [String]?
        var offers: [P2POffer]?
        var exchanged = false
        let wallet = Wallet(initialBalances: ["USD": 100, "BTC": 1])
        let offer = makeOffer(seller: "Repo")
        let ready = expectation(description: "publisher value")

        repository.loadCurrencies { result in
            if case .success(let list) = result { currencies = list }
        }
        repository.loadCurrenciesPublisher()
            .sink(receiveCompletion: { _ in }, receiveValue: { value in
                XCTAssertEqual(value, ["USD", "BTC"])
                ready.fulfill()
            })
            .store(in: &cancellables)
        repository.loadOffers(for: CurrencyPair(from: "USD", to: "BTC")) { result in
            if case .success(let list) = result { offers = list }
        }
        repository.performExchange(offer: offer, amount: 12, wallet: wallet) { result in
            if case .success = result { exchanged = true }
        }
        wait(for: [ready], timeout: 2)

        XCTAssertEqual(gateway.loadCurrenciesCount, 1)
        XCTAssertEqual(gateway.loadCurrenciesPublisherCount, 1)
        XCTAssertEqual(gateway.loadOffersCount, 1)
        XCTAssertEqual(gateway.performExchangeCount, 1)
        XCTAssertEqual(gateway.lastExchangeAmount, 12)
        XCTAssertTrue(exchanged)
        XCTAssertEqual(currencies, ["USD", "BTC"])
        XCTAssertNotNil(offers)
    }
}

final class NetworkServiceGatewayTests: XCTestCase {
    override func tearDown() {
        URLProtocolMock.reset()
        super.tearDown()
    }

    func test_loadCurrencies_success_parsit_and_sorts_currencies() {
        URLProtocolMock.handler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains("exchange-rates?currency=USD") == true)
            let json = """
            {
              "data": {
                "rates": {
                  "BTC": "0.0001",
                  "USD": "1",
                  "BROKEN": "abc"
                }
              }
            }
            """.data(using: .utf8)!
            return StubbedResponse(statusCode: 200, data: json)
        }
        let service = NetworkService(session: makeMockedSession())

        let ready = expectation(description: "currencies loaded")
        service.loadCurrencies { result in
            if case .success(let currencies) = result {
                XCTAssertEqual(currencies, ["BTC", "USD"])
                ready.fulfill()
            }
        }

        wait(for: [ready], timeout: 2)
    }

    func test_loadCurrencies_network_error_is_mapped_in_noInternet() {
        URLProtocolMock.handler = { _ in
            StubbedResponse(error: URLError(.notConnectedToInternet))
        }
        let service = NetworkService(session: makeMockedSession())

        let ready = expectation(description: "network error mapped")
        service.loadCurrencies { result in
            if case .failure(let error) = result {
                if case .noInternet = error {
                    ready.fulfill()
                }
            }
        }

        wait(for: [ready], timeout: 2)
    }

    func test_loadOffers_403_maps_to_forbiddenSection() {
        URLProtocolMock.handler = { _ in
            StubbedResponse(statusCode: 403, data: Data())
        }
        let service = NetworkService(session: makeMockedSession())

        let ready = expectation(description: "forbidden mapped")
        service.loadOffers(for: CurrencyPair(from: "USD", to: "BTC")) { result in
            if case .failure(let error) = result, case .forbiddenSection = error {
                ready.fulfill()
            }
        }

        wait(for: [ready], timeout: 2)
    }

    func test_loadOffers_if_the_required_rate_is_not_available_returns_parsing() {
        URLProtocolMock.handler = { _ in
            let json = """
            {
              "data": {
                "rates": {
                  "ETH": "2000"
                }
              }
            }
            """.data(using: .utf8)!
            return StubbedResponse(statusCode: 200, data: json)
        }
        let service = NetworkService(session: makeMockedSession())

        let ready = expectation(description: "missing pair parsing error")
        service.loadOffers(for: CurrencyPair(from: "USD", to: "BTC")) { result in
            if case .failure(let error) = result, case .parsing = error {
                ready.fulfill()
            }
        }

        wait(for: [ready], timeout: 2)
    }

    func test_performExchange_incorrect_amount_returns_unknown() {
        let service = NetworkService(session: makeMockedSession())
        let wallet = Wallet(initialBalances: ["USD": 100, "BTC": 1])
        let offer = makeOffer(seller: "BadAmount")

        let ready = expectation(description: "invalid amount")
        service.performExchange(offer: offer, amount: 0, wallet: wallet) { result in
            if case .failure(let error) = result, case .unknown = error {
                ready.fulfill()
            }
        }

        wait(for: [ready], timeout: 2)
    }
}

// MARK: - Mocks

private enum SequencedResponse {
    case immediate(Result<[P2POffer], NetworkServiceError>)
    case delayed(TimeInterval, Result<[P2POffer], NetworkServiceError>)
}

private final class MockRepository: P2PExchangeRepository {
    var loadCurrenciesCount = 0
    var loadCurrenciesPublisherCount = 0
    var loadOffersCount = 0
    var performExchangeCount = 0

    private let currenciesResult: Result<[String], NetworkServiceError>
    private let currenciesPublisherResult: Result<[String], NetworkServiceError>
    private let offersResult: Result<[P2POffer], NetworkServiceError>
    private let exchangeResult: Result<Void, NetworkServiceError>
    private let onPerformExchange: ((P2POffer, Double, Wallet) -> Void)?

    init(
        currenciesResult: Result<[String], NetworkServiceError> = .success(["USD", "BTC"]),
        currenciesPublisherResult: Result<[String], NetworkServiceError> = .success(["USD", "BTC"]),
        offersResult: Result<[P2POffer], NetworkServiceError> = .success([]),
        exchangeResult: Result<Void, NetworkServiceError> = .success(()),
        onPerformExchange: ((P2POffer, Double, Wallet) -> Void)? = nil
    ) {
        self.currenciesResult = currenciesResult
        self.currenciesPublisherResult = currenciesPublisherResult
        self.offersResult = offersResult
        self.exchangeResult = exchangeResult
        self.onPerformExchange = onPerformExchange
    }

    func loadCurrencies(completion: @escaping (Result<[String], NetworkServiceError>) -> Void) {
        loadCurrenciesCount += 1
        completion(currenciesResult)
    }

    func loadCurrenciesPublisher() -> AnyPublisher<[String], NetworkServiceError> {
        loadCurrenciesPublisherCount += 1
        switch currenciesPublisherResult {
        case .success(let currencies):
            return Just(currencies)
                .setFailureType(to: NetworkServiceError.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func loadOffers(for pair: CurrencyPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void) {
        loadOffersCount += 1
        completion(offersResult)
    }

    func performExchange(
        offer: P2POffer,
        amount: Double,
        wallet: Wallet,
        completion: @escaping (Result<Void, NetworkServiceError>) -> Void
    ) {
        performExchangeCount += 1
        onPerformExchange?(offer, amount, wallet)
        completion(exchangeResult)
    }
}

private final class SequencedOffersRepository: P2PExchangeRepository {
    var loadOffersCount = 0
    private var responses: [SequencedResponse]

    init(responses: [SequencedResponse]) {
        self.responses = responses
    }

    func loadCurrencies(completion: @escaping (Result<[String], NetworkServiceError>) -> Void) {
        completion(.success(["USD", "BTC"]))
    }

    func loadCurrenciesPublisher() -> AnyPublisher<[String], NetworkServiceError> {
        Just(["USD", "BTC"])
            .setFailureType(to: NetworkServiceError.self)
            .eraseToAnyPublisher()
    }

    func loadOffers(for pair: CurrencyPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void) {
        loadOffersCount += 1
        guard !responses.isEmpty else {
            completion(.success([]))
            return
        }
        let next = responses.removeFirst()
        switch next {
        case .immediate(let result):
            completion(result)
        case .delayed(let delay, let result):
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                completion(result)
            }
        }
    }

    func performExchange(
        offer: P2POffer,
        amount: Double,
        wallet: Wallet,
        completion: @escaping (Result<Void, NetworkServiceError>) -> Void
    ) {
        completion(.success(()))
    }
}

private final class MockGateway: P2PExchangeGateway {
    var loadCurrenciesCount = 0
    var loadCurrenciesPublisherCount = 0
    var loadOffersCount = 0
    var performExchangeCount = 0
    var lastExchangeAmount: Double?
    var offeredRates: [Double] = []

    func loadCurrencies(completion: @escaping (Result<[String], NetworkServiceError>) -> Void) {
        loadCurrenciesCount += 1
        completion(.success(["USD", "BTC"]))
    }

    func loadCurrenciesPublisher() -> AnyPublisher<[String], NetworkServiceError> {
        loadCurrenciesPublisherCount += 1
        return Just(["USD", "BTC"])
            .setFailureType(to: NetworkServiceError.self)
            .eraseToAnyPublisher()
    }

    func loadOffers(for pair: CurrencyPair, completion: @escaping (Result<[P2POffer], NetworkServiceError>) -> Void) {
        loadOffersCount += 1
        completion(.success([makeOffer(seller: "Gateway", pair: pair)]))
    }

    func performExchange(
        offer: P2POffer,
        amount: Double,
        wallet: Wallet,
        completion: @escaping (Result<Void, NetworkServiceError>) -> Void
    ) {
        performExchangeCount += 1
        lastExchangeAmount = amount
        offeredRates.append(offer.rate)
        completion(.success(()))
    }
}

private struct StubbedResponse {
    var statusCode: Int = 200
    var data: Data? = nil
    var error: Error? = nil
}

private final class URLProtocolMock: URLProtocol {
    static var handler: ((URLRequest) -> StubbedResponse)?

    static func reset() {
        handler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            XCTFail("URLProtocolMock.handler not set")
            return
        }

        let stub = handler(request)
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: stub.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private func makeMockedSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolMock.self]
    return URLSession(configuration: configuration)
}

private func makeOffer(
    seller: String,
    pair: CurrencyPair = CurrencyPair(from: "USD", to: "BTC"),
    rate: Double = 0.01,
    reserve: Double = 100
) -> P2POffer {
    P2POffer(
        sellerName: seller,
        pair: pair,
        rate: rate,
        reserve: reserve
    )
}

private func assertFailedState(_ state: P2PExchangeViewModel.ViewState, expected: NetworkServiceError) {
    guard case .failed(let error) = state else {
        XCTFail("Expected .failed state")
        return
    }
    switch (error, expected) {
    case (.noInternet, .noInternet),
         (.timeout, .timeout),
         (.parsing, .parsing),
         (.forbiddenSection, .forbiddenSection),
         (.unknown, .unknown):
        return
    case (.server(let lhs), .server(let rhs)):
        XCTAssertEqual(lhs, rhs)
    default:
        XCTFail("Unexpected error case")
    }
}
