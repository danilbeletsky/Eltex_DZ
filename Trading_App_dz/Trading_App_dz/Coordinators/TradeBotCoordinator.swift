import UIKit

final class TradeBotCoordinator: Coordinator {
    let navigationController = UINavigationController()

    func start() {
        let viewModel = TradeBotViewModel()
        let controller = ChatViewController(viewModel: viewModel, coordinator: self)
        controller.title = "Trade Bot"
        navigationController.tabBarItem = UITabBarItem(
            title: "Trade Bot",
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            tag: 0
        )
        navigationController.setViewControllers([controller], animated: false)
    }

    func showCandlesChart() {
        let chartsViewController = ChartsViewController()
        chartsViewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(chartsViewController, animated: true)
    }

    func showLineChart() {
        let chartsGrafViewController = ChartsGrafViewController()
        chartsGrafViewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(chartsGrafViewController, animated: true)
    }

    func showWallet(wallet: Wallet) {
        let walletVC = WalletViewController(wallet: wallet)
        let nav = UINavigationController(rootViewController: walletVC)
        nav.modalPresentationStyle = .formSheet
        navigationController.present(nav, animated: true)
    }

    func showShortCurrencySelection(currentPair: CurrencyPair, delegate: CurrencySelectionViewControllerDelegate) {
        let vc = ShortCurrencySelectionViewController()
        vc.delegate = delegate
        vc.currentPair = currentPair
        vc.onOpenFullList = { [weak self, weak vc] pair, delegate in
            guard let self else { return }
            vc?.dismiss(animated: true) {
                self.showFullCurrencySelection(currentPair: pair, delegate: delegate)
            }
        }
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        navigationController.present(vc, animated: true)
    }

    private func showFullCurrencySelection(currentPair: CurrencyPair, delegate: CurrencySelectionViewControllerDelegate) {
        let fullVC = CurrencySelectionViewController()
        fullVC.delegate = delegate
        fullVC.currentPair = currentPair
        navigationController.pushViewController(fullVC, animated: true)
    }
}
