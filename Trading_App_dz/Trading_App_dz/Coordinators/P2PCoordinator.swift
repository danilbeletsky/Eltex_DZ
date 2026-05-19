import UIKit

final class P2PCoordinator: Coordinator {
    let navigationController = UINavigationController()

    func start() {
        let viewModel = P2PExchangeViewModel()
        let controller = P2PExchangeViewController(viewModel: viewModel, coordinator: self)
        controller.title = "P2P"
        navigationController.tabBarItem = UITabBarItem(
            title: "P2P",
            image: UIImage(systemName: "person.2.wave.2"),
            tag: 3
        )
        navigationController.setViewControllers([controller], animated: false)
    }

    func showWallet(wallet: Wallet) {
        let walletVC = WalletViewController(wallet: wallet)
        let nav = UINavigationController(rootViewController: walletVC)
        nav.modalPresentationStyle = .formSheet
        navigationController.present(nav, animated: true)
    }

    func showCurrencySelection(currentPair: CurrencyPair, apiCurrencies: [String], delegate: CurrencySelectionViewControllerDelegate) {
        let vc = CurrencySelectionViewController()
        vc.delegate = delegate
        vc.currentPair = currentPair
        vc.apiCurrencies = apiCurrencies
        navigationController.pushViewController(vc, animated: true)
    }

    func showSellerInfo(offer: P2POffer) {
        let vm = SellerInfoViewModel(offer: offer)
        let controller = SellerInfoViewController(viewModel: vm)
        navigationController.pushViewController(controller, animated: true)
    }
}
