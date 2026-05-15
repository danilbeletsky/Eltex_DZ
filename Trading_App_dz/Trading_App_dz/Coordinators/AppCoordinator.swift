import UIKit

protocol Coordinator: AnyObject {
    func start()
}

final class AppCoordinator: Coordinator {
    private let window: UIWindow
    private var tabBarCoordinator: MainTabBarCoordinator?

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        window.rootViewController = makeSplashController()
        window.makeKeyAndVisible()
    }

    private func makeSplashController() -> UIViewController {
        SplashScreenViewController { [weak self] in
            self?.showInitialFlow()
        }
    }

    private func showInitialFlow() {
        if AuthSessionService.shared.canAutoLogin() {
            showMainApp()
        } else {
            showAuth()
        }
    }

    private func showAuth() {
        let authController = AuthViewController { [weak self] in
            self?.showMainApp()
        }
        setRoot(authController)
    }

    private func showMainApp() {
        let coordinator = MainTabBarCoordinator(onLogout: { [weak self] in
            self?.handleLogout()
        })
        tabBarCoordinator = coordinator
        coordinator.start()
        setRoot(coordinator.rootViewController)
    }

    private func handleLogout() {
        AuthSessionService.shared.logout()
        tabBarCoordinator = nil
        showAuth()
    }

    private func setRoot(_ controller: UIViewController) {
        UIView.transition(
            with: window,
            duration: 0.35,
            options: .transitionCrossDissolve
        ) {
            self.window.rootViewController = controller
        }
    }
}
