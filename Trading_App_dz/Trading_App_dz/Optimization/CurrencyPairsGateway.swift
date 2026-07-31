import Combine
import Foundation

protocol CurrencyPairsGateway: AnyObject {
    var snapshotPublisher: AnyPublisher<CurrencyPairsSnapshot, Never> { get }
    func start()
    func stop()
}

final class MockCurrencyPairsGateway: CurrencyPairsGateway {
    static let pairsCount = 500

    private let subject = CurrentValueSubject<CurrencyPairsSnapshot, Never>(
        CurrencyPairsSnapshot(pairs: [], lastUpdatedPairs: [], updateCycle: 0)
    )
    private var timer: Timer?

    var snapshotPublisher: AnyPublisher<CurrencyPairsSnapshot, Never> {
        subject.eraseToAnyPublisher()
    }

    func start() {
        guard timer == nil else { return }

        let initialPairs = Self.makePairs()
        subject.send(
            CurrencyPairsSnapshot(
                pairs: initialPairs,
                lastUpdatedPairs: Array(initialPairs.prefix(12)),
                updateCycle: 0
            )
        )

        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                self?.updateRandomPairs()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func updateRandomPairs() {
        let current = subject.value
        var updatedPairs = current.pairs
        let updateCount = Int.random(in: 8...35)
        var indexes = Set<Int>()

        while indexes.count < updateCount {
            indexes.insert(Int.random(in: updatedPairs.indices))
        }

        for index in indexes {
            updatedPairs[index].previousValue = updatedPairs[index].value
            updatedPairs[index].value = max(
                0.0001,
                updatedPairs[index].value * Double.random(in: 0.985...1.015)
            )
            updatedPairs[index].history.append(updatedPairs[index].value)

            if updatedPairs[index].history.count > 240 {
                updatedPairs[index].history.removeFirst(
                    updatedPairs[index].history.count - 240
                )
            }
        }

        subject.send(
            CurrencyPairsSnapshot(
                pairs: updatedPairs,
                lastUpdatedPairs: indexes.sorted().map { updatedPairs[$0] },
                updateCycle: current.updateCycle + 1
            )
        )
    }

    private static func makePairs() -> [FXCurrencyPair] {
        (0..<pairsCount).map { _ in
            var value = Double.random(in: 0.5...180)
            var history: [Double] = []

            for _ in 0..<120 {
                value = max(0.0001, value * Double.random(in: 0.995...1.005))
                history.append(value)
            }

            return FXCurrencyPair(
                id: UUID(),
                name: "\(randomCode())/\(randomCode())",
                value: value,
                previousValue: history.dropLast().last ?? value,
                history: history
            )
        }
    }

    private static func randomCode() -> String {
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return String((0..<3).map { _ in letters.randomElement()! })
    }
}
