import Combine
import Foundation

protocol ObserveCurrencyPairsUseCase {
    func execute() -> AnyPublisher<CurrencyPairsSnapshot, Never>
    func start()
    func stop()
}

protocol CalculateCurrencyPairMetricsUseCase {
    func execute(pair: FXCurrencyPair) -> FXCurrencyPairMetrics
}

protocol BuildCurrencyPairRowsUseCase {
    func execute(
        snapshot: CurrencyPairsSnapshot,
        highlightRisk: Bool
    ) async -> CurrenciesListViewState.Content
}

final class ObserveCurrencyPairsUseCaseImpl: ObserveCurrencyPairsUseCase {
    private let repository: CurrencyPairsRepository

    init(repository: CurrencyPairsRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<CurrencyPairsSnapshot, Never> {
        repository.snapshotPublisher
    }

    func start() {
        repository.startObserving()
    }

    func stop() {
        repository.stopObserving()
    }
}

final class CalculateCurrencyPairMetricsUseCaseImpl: CalculateCurrencyPairMetricsUseCase {
    func execute(pair: FXCurrencyPair) -> FXCurrencyPairMetrics {
        let priceText = CurrencyPairMapper.formatPrice(pair.value, fractionDigits: 4...6)
        let history = pair.history
        var returns: [Double] = []

        if history.count > 1 {
            for index in 1..<history.count {
                let previous = max(history[index - 1], 0.0001)
                returns.append(log(history[index] / previous))
            }
        }

        let averageReturn = returns.reduce(0, +) / Double(max(returns.count, 1))
        let variance = returns.reduce(0) {
            $0 + pow($1 - averageReturn, 2)
        } / Double(max(returns.count, 1))
        let volatility = sqrt(variance) * sqrt(252)

        var gains = 0.0
        var losses = 0.0
        let startIndex = max(1, history.count - 14)

        if history.count > 1 {
            for index in startIndex..<history.count {
                let diff = history[index] - history[index - 1]
                if diff >= 0 {
                    gains += diff
                } else {
                    losses += abs(diff)
                }
            }
        }

        let rsi: Double
        if losses == 0 {
            rsi = 100
        } else {
            let rs = gains / losses
            rsi = 100 - 100 / (1 + rs)
        }

        var simulatedLosses = [Double](repeating: 0, count: 200)
        for path in 0..<200 {
            var simulatedPrice = pair.value
            for _ in 0..<30 {
                let noise = Double.random(in: -1...1)
                simulatedPrice *= exp(averageReturn + volatility * 0.02 * noise)
            }
            simulatedLosses[path] = pair.value - simulatedPrice
        }

        let sortedLosses = simulatedLosses.sorted()
        let valueAtRisk = sortedLosses[
            min(sortedLosses.count - 1, Int(Double(sortedLosses.count) * 0.95))
        ]

        let checksum = abs(pair.name.hashValue ^ Int(pair.value * 1000))

        return FXCurrencyPairMetrics(
            volatility: volatility,
            rsi: rsi,
            valueAtRisk: valueAtRisk,
            priceText: priceText,
            isGrowing: pair.isGrowing,
            checksum: checksum
        )
    }
}

final class BuildCurrencyPairRowsUseCaseImpl: BuildCurrencyPairRowsUseCase {
    private let metricsUseCase: CalculateCurrencyPairMetricsUseCase

    init(metricsUseCase: CalculateCurrencyPairMetricsUseCase) {
        self.metricsUseCase = metricsUseCase
    }

    func execute(
        snapshot: CurrencyPairsSnapshot,
        highlightRisk: Bool
    ) async -> CurrenciesListViewState.Content {
        await Task.detached(priority: .userInitiated) {
            let rows = snapshot.pairs.map { pair in
                let metrics = self.metricsUseCase.execute(pair: pair)
                return CurrencyPairMapper.mapRow(
                    pair: pair,
                    metrics: metrics,
                    highlightRisk: highlightRisk
                )
            }

            let recentPairs = snapshot.lastUpdatedPairs.map { pair in
                let metrics = self.metricsUseCase.execute(pair: pair)
                return CurrencyPairMapper.mapRecentCard(pair: pair, metrics: metrics)
            }

            return CurrenciesListViewState.Content(
                highlightRisk: highlightRisk,
                updateCycle: snapshot.updateCycle,
                recentPairs: recentPairs,
                rows: rows
            )
        }.value
    }
}
