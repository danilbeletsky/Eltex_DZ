import SwiftUI
import UIKit

final class CurrenciesListAssembly {
    @MainActor
    func assembly() -> UIViewController {
        let gateway = MockCurrencyPairsGateway()
        let repository = CurrencyPairsRepositoryImpl(gateway: gateway)
        let observeUseCase = ObserveCurrencyPairsUseCaseImpl(repository: repository)
        let metricsUseCase = CalculateCurrencyPairMetricsUseCaseImpl()
        let buildRowsUseCase = BuildCurrencyPairRowsUseCaseImpl(metricsUseCase: metricsUseCase)
        let viewModel = CurrenciesListViewModel(
            observeUseCase: observeUseCase,
            buildRowsUseCase: buildRowsUseCase
        )
        let view = CurrenciesListView(viewModel: viewModel)
        return UIHostingController(rootView: view)
    }
}
