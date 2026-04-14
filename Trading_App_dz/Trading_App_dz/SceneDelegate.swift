import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = createRootConstroller()
        
        window?.makeKeyAndVisible()
    }
}

private extension SceneDelegate {
    func createRootConstroller() -> UITabBarController {
        let tabBarController = UITabBarController()
        
        let chatViewController = ChatViewController()
        chatViewController.title = "Trade Chat"
        chatViewController.tabBarItem = UITabBarItem(
            title: "Trade",
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            tag: 0
        )
        let chatNavigationController = UINavigationController(rootViewController: chatViewController)
        
        let chartsViewController = ChartsViewController()
        chartsViewController.title = "Charts Candles"
        chartsViewController.tabBarItem = UITabBarItem(title: "Charts Candles", image: UIImage(systemName: "graph.2d"), tag: 1)
        
        let chartsGrafViewController = ChartsGrafViewController()
        chartsGrafViewController.title = "Charts Candles"
        chartsGrafViewController.tabBarItem = UITabBarItem(title: "Charts Graf", image: UIImage(systemName: "graph.3d"), tag: 2)
        
        tabBarController.viewControllers =  [chartsViewController, chartsGrafViewController, chatNavigationController]
        
        return tabBarController
    }
}

