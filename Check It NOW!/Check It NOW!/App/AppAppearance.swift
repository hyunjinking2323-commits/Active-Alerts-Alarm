    //
    //  AppAppearance.swift
    //  Check It NOW!
    //
    //  Created by t2025-m0239 on 2026.03.27.
    //

import UIKit

    /// 앱 전역 UI 스타일 관리
    /// 호출 위치: `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
enum AppAppearance {

        // MARK: - Global Style

    static func applyGlobalStyle() {
        applyNavigationBar()
    }

        // MARK: - Navigation Bar

    private static func applyNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor          = .black
        appearance.titleTextAttributes      = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

            // standard / scrollEdge / compact 세 가지 상태 모두 동일하게 적용
        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance

            // 뒤로가기 버튼 및 바 버튼 색상
        UINavigationBar.appearance().tintColor = .white
    }
}
