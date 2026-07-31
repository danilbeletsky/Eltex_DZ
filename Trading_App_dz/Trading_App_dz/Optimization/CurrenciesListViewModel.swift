import Combine
import Foundation

enum CurrenciesListViewState: Equatable {
    case loading
    case content(Content)
    case empty

    struct Content: Equatable {
        var highlightRisk: Bool
        var updateCycle: Int
        var recentPairs: [RecentPairCardState]
        var rows: [CurrencyPairRowState]
    }
}

enum CurrenciesListIntent {
    case onAppear
    case onDisappear
    case setHighlightRisk(Bool)
}

@MainActor
final class CurrenciesListViewModel: ObservableObject {
    @Published private(set) var state: CurrenciesListViewState = .loading

    private let observeUseCase: ObserveCurrencyPairsUseCase
    private let buildRowsUseCase: BuildCurrencyPairRowsUseCase
    private var cancellables = Set<AnyCancellable>()
    private var highlightRisk = false
    private var snapshotGeneration = 0

    init(
        observeUseCase: ObserveCurrencyPairsUseCase,
        buildRowsUseCase: BuildCurrencyPairRowsUseCase
    ) {
        self.observeUseCase = observeUseCase
        self.buildRowsUseCase = buildRowsUseCase
    }

    func send(_ intent: CurrenciesListIntent) {
        switch intent {
        case .onAppear:
            guard cancellables.isEmpty else { return }
            observeUseCase.start()
            bindSnapshotUpdates()
        case .onDisappear:
            observeUseCase.stop()
            cancellables.removeAll()
            snapshotGeneration += 1
        case .setHighlightRisk(let isEnabled):
            highlightRisk = isEnabled
            if case .content(let content) = state {
                state = .content(
                    CurrenciesListViewState.Content(
                        highlightRisk: isEnabled,
                        updateCycle: content.updateCycle,
                        recentPairs: content.recentPairs,
                        rows: content.rows.map { row in
                            CurrencyPairRowState(
                                id: row.id,
                                name: row.name,
                                priceText: row.priceText,
                                isGrowing: row.isGrowing,
                                rsi: row.rsi,
                                volatility: row.volatility,
                                valueAtRisk: row.valueAtRisk,
                                isHighlighted: isEnabled && row.volatility > 0.12
                            )
                        }
                    )
                )
            }
        }
    }

    private func bindSnapshotUpdates() {
        observeUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.handleSnapshot(snapshot)
            }
            .store(in: &cancellables)
    }

    private func handleSnapshot(_ snapshot: CurrencyPairsSnapshot) {
        guard !snapshot.pairs.isEmpty else {
            if case .content = state { return }
            return
        }

        snapshotGeneration += 1
        let generation = snapshotGeneration

        Task { [weak self] in
            guard let self else { return }
            let content = await buildRowsUseCase.execute(
                snapshot: snapshot,
                highlightRisk: highlightRisk
            )
            guard generation == snapshotGeneration else { return }
            state = .content(content)
        }
    }
}
