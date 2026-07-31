import Foundation
import UIKit
import SwiftUI

final class HeatmapAssembly {
    func assembly() -> UIViewController {
        let view = HeatmapScreen()
        let hostingController = UIHostingController(rootView: view)
        return hostingController
    }

    
}
