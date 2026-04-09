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
        chartsViewController.title = "Charts"
        chartsViewController.tabBarItem = UITabBarItem(title: "Charts", image: UIImage(systemName: "graph.2d"), tag: 1)
        
        tabBarController.viewControllers = [chartsViewController, chatNavigationController]
        
        return tabBarController
    }
}

