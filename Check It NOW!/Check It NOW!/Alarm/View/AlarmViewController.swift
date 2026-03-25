

//
//  AlarmViewController.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.23.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class AlarmViewController: BaseViewController {


        // MARK: - Properties & ViewModel
    private let viewModel = AlarmViewModel()
    private let addAlarmRelay = PublishRelay<AlarmModel>()
    private let updateAlarmRelay = PublishRelay<AlarmModel>()
    private let deleteAlarmRelay = PublishRelay<Int>()

        // MARK: - UI Components
    private let bannerView = UIView().then {
        $0.backgroundColor = UIColor(white: 0.15, alpha: 1)

        $0.layer.cornerRadius = 10
        $0.isHidden = true
    }

    private let bannerLabel = UILabel().then {

        $0.font = .systemFont(ofSize: 13)
        $0.textColor = UIColor(white: 0.85, alpha: 1)
        $0.textAlignment = .center
    }

    private let tableView = UITableView(frame: .zero, style: .plain).then {
        $0.backgroundColor = .clear
        $0.separatorColor = UIColor(white: 0.25, alpha: 1)
        $0.register(AlarmCell.self, forCellReuseIdentifier: AlarmCell.identifier)
        $0.rowHeight = 80
    }

        // MARK: - Life Cycle (BaseViewController Methods)
    override func setupHierarchy() {
        [bannerView, tableView].forEach { view.addSubview($0) }
        bannerView.addSubview(bannerLabel)

    }

    override func setupLayout() {
        bannerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)

            $0.height.equalTo(32)
        }

        bannerLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        tableView.snp.makeConstraints {
            $0.top.equalTo(bannerView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    override func bind() {
        setupNavigationBar()

        let input = AlarmViewModel.Input(
            viewDidLoad: Observable.just(()),
            addAlarm: addAlarmRelay,
            updateAlarm: updateAlarmRelay,
            deleteAlarm: deleteAlarmRelay
        )

        let output = viewModel.transform(input: input)

            // 1. 테이블뷰 데이터 바인딩
        output.alarmList
            .bind(to: tableView.rx.items(cellIdentifier: AlarmCell.identifier, cellType: AlarmCell.self)) { [weak self] _, model, cell in
                guard let self = self else { return }
                cell.configure(with: model)
                cell.toggle.rx.isOn.skip(1)
                    .map { var m = model; m.isEnabled = $0; return m }
                    .bind(to: self.updateAlarmRelay)
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: disposeBag)

            // 2. 배너 텍스트 업데이트
        output.nextFireText
            .subscribe(onNext: { [weak self] text in
                self?.bannerLabel.text = text
                self?.bannerView.isHidden = (text == nil)
            })
            .disposed(by: disposeBag)

            // 3. 알람 발생 핸들링
        output.alarmFired
            .subscribe(onNext: { [weak self] alarm in
                self?.presentAlarmAlert(alarm)
            })
            .disposed(by: disposeBag)

            // 4. 삭제 및 편집 모드 관리
        tableView.rx.itemDeleted
            .map { $0.row }
            .bind(to: deleteAlarmRelay)
            .disposed(by: disposeBag)

        editButtonItem.rx.tap
            .map { [weak self] in !(self?.tableView.isEditing ?? false) }
            .subscribe(onNext: { [weak self] isEditing in
                self?.tableView.setEditing(isEditing, animated: true)
                self?.editButtonItem.title = isEditing ? "완료" : "편집"
            })
            .disposed(by: disposeBag)

            // 5. 셀 선택 (수정 화면 전환)
        tableView.rx.modelSelected(AlarmModel.self)
            .subscribe(onNext: { [weak self] alarm in
                self?.showEditSheet(alarm)

            })
            .disposed(by: disposeBag)
    }

        // MARK: - Navigation & Actions
    private func setupNavigationBar() {
            // 1. 커스텀 타이틀 라벨 생성 (중앙 고정용)
        let navTitleLabel = UILabel().then {
            $0.text = "알람"
            $0.font = .systemFont(ofSize: 28, weight: .semibold) // 순정 앱 느낌의 폰트 사이즈
            $0.textColor = .white
            $0.textAlignment = .center
        }

            // 2. 네비게이션 바 중앙에 커스텀 뷰 배치
        navigationItem.titleView = navTitleLabel

            // 3. 라지 타이틀 해제 (중앙에 작게 띄우기 위해 필수)
        navigationController?.navigationBar.prefersLargeTitles = false

            // 4. 왼쪽/오른쪽 버튼 설정
        navigationItem.leftBarButtonItem = editButtonItem
        editButtonItem.title = "편집"

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        navigationItem.rightBarButtonItem = addButton

        addButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.showAddSheet() })
            .disposed(by: disposeBag)
    }
    private func showAddSheet() {
        let vc = AddAlarmViewController()
        vc.onSave = { [weak self] in self?.addAlarmRelay.accept($0) }
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func showEditSheet(_ alarm: AlarmModel) {
        let vc = AddAlarmViewController(alarm: alarm)
        vc.onSave = { [weak self] in self?.updateAlarmRelay.accept($0) }
        vc.onDelete = { [weak self] in
            guard let self = self else { return }
            if let index = self.viewModel.currentAlarms.firstIndex(where: { $0.id == alarm.id }) {
                self.deleteAlarmRelay.accept(index)
            }
        }
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func presentAlarmAlert(_ alarm: AlarmModel) {
        let alert = UIAlertController(title: "알람", message: alarm.label, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "중단", style: .destructive) { [weak self] _ in
            self?.viewModel.stopSound()
        })
        present(alert, animated: true)
    }
}
