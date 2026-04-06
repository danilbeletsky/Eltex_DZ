//
//  SceneDelegate.swift
//  Trading_App_dz_9
//
//  Created by Данил Белецкий on 06.04.2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = CurrencySelectionViewController()
        
        window?.makeKeyAndVisible()
    }

}

