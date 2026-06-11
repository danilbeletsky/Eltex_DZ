import UIKit

final class HeatmapCoordinator: Coordinator {
    let navigationController = UINavigationController()

    func start() {
        let controller = HeatmapAssembly().assembly()
        controller.title = "Heatmap"
        navigationController.tabBarItem = UITabBarItem(
            title: "Heatmap",
            image: UIImage(systemName: "square.grid.3x3.fill"),
            tag: 5
        )
        navigationController.setViewControllers([controller], animated: false)
    }
}
