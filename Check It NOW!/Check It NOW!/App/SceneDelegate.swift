    //
    //  SceneDelegate.swift
    //  Check It NOW!
    //

import UIKit
import Then

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

        // MARK: - Scene Connection

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene).then {
            $0.rootViewController = MainTabBarController()
            $0.makeKeyAndVisible()
        }
    }

        // MARK: - Scene Lifecycle

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
