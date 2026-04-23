import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = createSplashController()
        
        window?.makeKeyAndVisible()
    }
}

private extension SceneDelegate {
    func createSplashController() -> SplashScreenViewController {
        SplashScreenViewController { [weak self] in
            self?.showMainApp()
        }
    }

    func showMainApp() {
        let mainController = createRootConstroller()
        guard let window else { return }

        UIView.transition(
            with: window,
            duration: 0.35,
            options: .transitionCrossDissolve
        ) {
            window.rootViewController = mainController
        }
    }

    func createRootConstroller() -> UITabBarController {
        let tabBarController = UITabBarController()
        
        let chatViewController = ChatViewController()
        chatViewController.title = "Trade Bot"
        chatViewController.tabBarItem = UITabBarItem(
            title: "Trade Bot",
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            tag: 0
        )
        let chatNavigationController = UINavigationController(rootViewController: chatViewController)

        let p2pViewController = P2PExchangeViewController()
        p2pViewController.title = "P2P"
        p2pViewController.tabBarItem = UITabBarItem(
            title: "P2P",
            image: UIImage(systemName: "person.2.wave.2"),
            tag: 3
        )
        let p2pNavigationController = UINavigationController(rootViewController: p2pViewController)
        
        let chartsViewController = ChartsViewController()
        chartsViewController.title = "Charts Candles"
        chartsViewController.tabBarItem = UITabBarItem(title: "Charts Candles", image: UIImage(systemName: "graph.2d"), tag: 1)
        
        let chartsGrafViewController = ChartsGrafViewController()
        chartsGrafViewController.title = "Charts Candles"
        chartsGrafViewController.tabBarItem = UITabBarItem(title: "Charts Graf", image: UIImage(systemName: "graph.3d"), tag: 2)
        
        tabBarController.viewControllers =  [chartsViewController, chartsGrafViewController, chatNavigationController, p2pNavigationController]
        
        return tabBarController
    }
}

