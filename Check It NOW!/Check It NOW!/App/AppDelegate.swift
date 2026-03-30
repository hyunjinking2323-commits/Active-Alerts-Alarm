    //
    //  AppDelegate.swift
    //  Check It NOW!
    //
    //  Created by t2025-m0239 on 2026.03.20.
    //

import UIKit
import CoreData
import AVFoundation

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

        // MARK: - App Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AppAppearance.applyGlobalStyle()
        configureAudioSession()
        return true
    }

        // MARK: - Audio Session

        /// 무음 모드 / 백그라운드에서도 타이머 알람이 재생되도록 AVAudioSession 설정
        /// - `.playback`: 무음 스위치 ON 상태에서도 소리 재생
        /// - `.mixWithOthers`: 음악 앱 등 다른 오디오와 동시 재생 허용
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession 설정 실패: \(error)")
        }
    }

        // MARK: - Scene Session Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {}

        // MARK: - Core Data Stack

        /// lazy var → 처음 접근 시 한 번만 초기화
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Check_It_NOW_")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data 저장소 로드 실패: \(error), \(error.userInfo)")
            }
        }
        return container
    }()

        // MARK: - Core Data Save

        /// 변경 사항이 있을 때만 저장 (불필요한 I/O 방지)
    func saveContext() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Core Data 저장 실패: \(nserror), \(nserror.userInfo)")
        }
    }
}
