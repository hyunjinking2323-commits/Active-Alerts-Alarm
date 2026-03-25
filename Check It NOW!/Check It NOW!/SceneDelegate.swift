//
//  SceneDelegate.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.20.
//

import UIKit
import SnapKit
import Then

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
            // 1. 새로운 윈도우 생성
        let window = UIWindow(windowScene: windowScene)
        
            // 탭 바 컨트롤러를 루트로 설정.
        window.rootViewController = createTabBarController()
        window.makeKeyAndVisible()
        self.window = window
    }
        // 탭 바와 각 화면의 연결을 담당하는 메서드
    private func createTabBarController() -> UITabBarController {
        let worldClockVC = UINavigationController(rootViewController: WorldClockViewController()).then {
            $0.tabBarItem = UITabBarItem(title: "세계 시계", image: UIImage(systemName: "globe"), tag: 0)
        }
        let alarmVC = UINavigationController(rootViewController: AlarmViewController()).then {
            $0.tabBarItem = UITabBarItem(title: "알람", image: UIImage(systemName: "alarm.fill"), tag: 1)
        }
        let stopwatchVC = UINavigationController(rootViewController: StopWatchViewController()).then {
            $0.tabBarItem = UITabBarItem(title: "스톱워치", image: UIImage(systemName: "stopwatch.fill"), tag: 2)
        }
        let timerVC = UINavigationController(rootViewController: TimerViewController()).then {
            $0.tabBarItem = UITabBarItem(title: "타이머", image: UIImage(systemName: "timer"), tag: 3)
        }
        return UITabBarController().then {
            $0.viewControllers = [worldClockVC, alarmVC, stopwatchVC, timerVC]
            $0.selectedIndex = 1
            $0.tabBar.tintColor = .systemOrange
            $0.tabBar.backgroundColor = .systemBackground
        }
    }
}
    func sceneDidDisconnect(_ scene: UIScene) {
        // 시스템이 씬과 연결을 끊을 때 호출됩니다. 앱이 백그라운드로 들어간 직후나 세션이 삭제될 때 발생하며, 다음에 다시 연결될 때 새로 만들 수 있는 자원들을 여기서 해제합니다.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // 씬이 비활성 상태에서 활성 상태로 전환되었을 때 호출됩니다. 앱이 멈춰있을 때 중단되었던 작업이나 아직 시작되지 않은 작업들을 다시 실행하는 용도로 사용합니다.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // 씬이 활성 상태에서 비활성 상태로 전환되기 직전에 호출됩니다. 전화가 오거나 알림창이 내려오는 등의 일시적인 방해 상황에서 주로 발생합니다.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // 씬이 백그라운드에서 포그라운드(화면)로 올라올 때 호출됩니다. 백그라운드에 들어갈 때 변경했던 설정들을 다시 원래대로 되돌리는 코드를 작성합니다.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // 씬이 포그라운드에서 백그라운드로 완전히 내려갔을 때 호출됩니다. 데이터를 저장하거나 공유 자원을 해제하고, 나중에 앱을 다시 켰을 때 현재 상태를 복구할 수 있도록 정보를 저장합니다.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }



