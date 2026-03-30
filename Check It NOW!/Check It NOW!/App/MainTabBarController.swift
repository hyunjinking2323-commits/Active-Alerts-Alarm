    //
    //  MainTabBarController.swift
    //  Check It NOW!
    //

import UIKit
import Then

    /// iOS 26 Liquid Glass 탭바를 우회하기 위해
    /// UITabBarController 대신 UIViewController + CustomTabBarView 조합으로 구현
final class MainTabBarController: UIViewController {

        // MARK: - Tab

    private enum Tab: Int, CaseIterable {
        case alarm, stopwatch, timer

        var title: String {
            switch self {
                case .alarm:     return "알람"
                case .stopwatch: return "스톱워치"
                case .timer:     return "타이머"
            }
        }

        var icon: String {
            switch self {
                case .alarm:     return "alarm.fill"
                case .stopwatch: return "stopwatch.fill"
                case .timer:     return "timer"
            }
        }
    }

        // MARK: - Properties

    private lazy var navigationControllers: [UINavigationController] = [
        makeNav(root: AlarmViewController(),     tab: .alarm),
        makeNav(root: StopWatchViewController(), tab: .stopwatch),
        makeNav(root: TimerListViewController(), tab: .timer)
    ]

    private var selectedIndex = 0

        // MARK: - UI

        /// 각 탭의 컨텐츠가 표시되는 영역
    private let containerView = UIView()
        /// UITabBar를 사용하지 않는 커스텀 탭바
    private let customTabBar  = CustomTabBarView()

        // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupHierarchy()
        setupLayout()
        setupViewControllers()
        setupCustomTabBar()
        selectTab(at: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
            // containerView bounds 확정 후 모든 자식 VC frame 갱신
        navigationControllers.forEach { $0.view.frame = containerView.bounds }
    }

        // MARK: - Setup

    private func setupHierarchy() {
        view.addSubview(containerView)
        view.addSubview(customTabBar)
    }

    private func setupLayout() {
        customTabBar.translatesAutoresizingMaskIntoConstraints  = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            customTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            customTabBar.heightAnchor.constraint(equalToConstant: 64),

            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

        /// 앱 시작 시 모든 VC를 미리 생성해 containerView에 추가
        /// 탭 전환 시 제거/추가 없이 show/hide만 → 첫 진입 지연 없음
    private func setupViewControllers() {
        navigationControllers.forEach { navVC in
            addChild(navVC)
            containerView.addSubview(navVC.view)
            navVC.view.frame            = containerView.bounds
            navVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            navVC.view.isHidden         = true
            navVC.didMove(toParent: self)
        }
    }

    private func setupCustomTabBar() {
        let items = Tab.allCases.map { CustomTabBarView.Item(title: $0.title, icon: $0.icon) }
        customTabBar.configure(items: items)
        customTabBar.onTabSelected = { [weak self] index in
            self?.selectTab(at: index)
        }
        customTabBar.setSelected(index: 0)
    }

        // MARK: - Tab Selection

    private func selectTab(at index: Int) {
        guard index != selectedIndex || navigationControllers[index].view.isHidden else {
            if navigationControllers[index].view.isHidden { showTab(index) }
            return
        }

            // 기존 탭 숨기기
        navigationControllers[selectedIndex].view.isHidden = true

            // 새 탭 보이기
        showTab(index)

        selectedIndex = index
        customTabBar.setSelected(index: index)
    }

    private func showTab(_ index: Int) {
        let navVC = navigationControllers[index]
        navVC.view.isHidden = false
            // 탭 전환 시 viewWillAppear / viewDidAppear 수동 호출
        navVC.beginAppearanceTransition(true, animated: false)
        navVC.endAppearanceTransition()
    }

        // MARK: - Helpers

    private func makeNav(root: UIViewController, tab: Tab) -> UINavigationController {
        UINavigationController(rootViewController: root).then {
            $0.tabBarItem = UITabBarItem(title: tab.title, image: UIImage(systemName: tab.icon), tag: tab.rawValue)
        }
    }
}
