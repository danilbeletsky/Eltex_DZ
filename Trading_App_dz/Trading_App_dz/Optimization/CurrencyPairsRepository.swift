import Combine
import Foundation

protocol CurrencyPairsRepository {
    var snapshotPublisher: AnyPublisher<CurrencyPairsSnapshot, Never> { get }
    func startObserving()
    func stopObserving()
}

final class CurrencyPairsRepositoryImpl: CurrencyPairsRepository {
    private let gateway: CurrencyPairsGateway

    init(gateway: CurrencyPairsGateway) {
        self.gateway = gateway
    }

    var snapshotPublisher: AnyPublisher<CurrencyPairsSnapshot, Never> {
        gateway.snapshotPublisher
    }

    func startObserving() {
        gateway.start()
    }

    func stopObserving() {
        gateway.stop()
    }
}
