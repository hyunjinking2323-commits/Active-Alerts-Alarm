    // RepeatDayViewController.swift
import UIKit
import RxSwift
import RxCocoa
import Then
import SnapKit

final class RepeatDayViewController: BaseViewController {

        // MARK: - [데이터 및 상태 관리]
    private let dayNames = ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]
    private var selected: [Int] // 선택된 요일 인덱스 배열
    private let onDone: ([Int]) -> Void // 화면이 닫힐 때 데이터를 넘겨줄 클로저

        // MARK: - [초기화]
    init(selected: [Int], onDone: @escaping ([Int]) -> Void) {
        self.selected = selected
        self.onDone   = onDone
        super.init() // BaseViewController의 init 호출
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - [UI 컴포넌트 선언]
    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "day")
        $0.dataSource = self // 셀 구성은 DataSource에서 처리
    }

        // MARK: - [계층 구조 및 레이아웃]
    override func setupHierarchy() {
        view.addSubview(tableView)
    }

    override func setupLayout() {
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

        // MARK: - [RxSwift 바인딩]
    override func bind() {
            // 네비게이션 설정
        title = "반복"
        setupNavigationBarAppearance()

            // 테이블뷰 셀 선택 로직 (Rx 적용)
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)

                let day = indexPath.row
                if let idx = self.selected.firstIndex(of: day) {
                    self.selected.remove(at: idx) // 이미 있으면 제거
                } else {
                    self.selected.append(day) // 없으면 추가
                }

                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            })
            .disposed(by: disposeBag)
    }

        // MARK: - [생명주기 및 기타]
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDone(selected) // 화면이 사라지기 직전에 선택된 데이터 전달
    }

    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance().then {
            $0.configureWithOpaqueBackground()
            $0.backgroundColor     = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
}

    // MARK: - [UITableViewDataSource]
extension RepeatDayViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "day", for: indexPath)

        cell.textLabel?.text      = dayNames[indexPath.row]
        cell.textLabel?.textColor = .white
        cell.backgroundColor      = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        cell.tintColor            = UIColor(red: 1, green: 0.62, blue: 0.04, alpha: 1) // 오렌지색 체크마크

            // 선택 여부에 따라 체크마크 표시 여부 결정
        cell.accessoryType = selected.contains(indexPath.row) ? .checkmark : .none

        return cell
    }
}
