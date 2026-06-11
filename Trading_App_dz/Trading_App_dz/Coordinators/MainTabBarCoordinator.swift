import UIKit

final class MainTabBarCoordinator: Coordinator {
    let rootViewController = UITabBarController()

    private let onLogout: () -> Void
    private let tradeBotCoordinator = TradeBotCoordinator()
    private let p2pCoordinator = P2PCoordinator()
    private let heatmapCoordinator = HeatmapCoordinator()

    init(onLogout: @escaping () -> Void) {
        self.onLogout = onLogout
    }

    func start() {
        tradeBotCoordinator.start()
        p2pCoordinator.start()
        heatmapCoordinator.start()

        let chartsViewController = ChartsViewController()
        chartsViewController.title = "Charts Candles"
        chartsViewController.tabBarItem = UITabBarItem(title: "Charts Candles", image: UIImage(systemName: "graph.2d"), tag: 1)

        let chartsGrafViewController = ChartsGrafViewController()
        chartsGrafViewController.title = "Charts Graf"
        chartsGrafViewController.tabBarItem = UITabBarItem(title: "Charts Graf", image: UIImage(systemName: "graph.3d"), tag: 2)

        let currenciesListViewController = CurrenciesListAssembly().assembly()
        currenciesListViewController.title = "Currencies"
        currenciesListViewController.tabBarItem = UITabBarItem(
            title: "Currencies",
            image: UIImage(systemName: "dollarsign.circle"),
            tag: 3
        )

        let settings = SettingsController(onLogoutRequested: onLogout)
        settings.title = "Settings"
        settings.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: 4)

        rootViewController.viewControllers = [
            chartsViewController,
            chartsGrafViewController,
            currenciesListViewController,
            heatmapCoordinator.navigationController,
            tradeBotCoordinator.navigationController,
            p2pCoordinator.navigationController,
            settings
        ]
    }
}
