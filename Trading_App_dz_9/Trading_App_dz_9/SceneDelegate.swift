import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = createRootController()
        
        window?.makeKeyAndVisible()
    }
}

private extension SceneDelegate {
    func createRootController() -> UITabBarController {
        let tabBarController = UITabBarController()
        
        let chatViewController = ChatViewController()
        chatViewController.title = "Trade Chat"
        chatViewController.tabBarItem = UITabBarItem(
            title: "Trade",
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            tag: 0
        )
        let chatNavigationController = UINavigationController(rootViewController: chatViewController)
        
        tabBarController.viewControllers = [chatNavigationController]
        
        return tabBarController
    }
}

