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

    private let viewModel = AlarmViewModel()
    private var snoozeCountMap: [UUID: Int] = [:]
    private let maxSnoozeCount = 3
    private let snoozeOptions: [(label: String, minutes: Int)] = [
        ("5분", 5), ("10분", 10), ("15분", 15), ("30분", 30)
    ]

        // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .plain).then {
        $0.backgroundColor = .clear
        $0.separatorColor  = UIColor(white: 0.25, alpha: 1)
        $0.register(AlarmCell.self, forCellReuseIdentifier: AlarmCell.identifier)
    }

    private let bannerView = UIView().then {
        $0.backgroundColor    = UIColor(white: 0.15, alpha: 1)
        $0.layer.cornerRadius = 10
        $0.isHidden = true
    }

    private let bannerLabel = UILabel().then {
        $0.font      = .systemFont(ofSize: 13)
        $0.textColor = UIColor(white: 0.85, alpha: 1)
    }

        // MARK: - Base Methods
    override func setupHierarchy() {
        bannerView.addSubview(bannerLabel)
        [bannerView, tableView].forEach { view.addSubview($0) }
    }

    override func setupLayout() {
        bannerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.height.equalTo(40)
        }
        bannerLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        tableView.snp.makeConstraints {
            $0.top.equalTo(bannerView.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func bind() {
        setupNavigationBar()

            // 알람 리스트 갱신
        viewModel.alarms
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.tableView.reloadData() })
            .disposed(by: disposeBag)

            // 배너 텍스트 바인딩
        viewModel.nextFireText
            .asDriver()
            .drive(onNext: { [weak self] text in
                self?.bannerView.isHidden = text == nil
                self?.bannerLabel.text    = text
            })
            .disposed(by: disposeBag)

            // 알람 발화 이벤트
        viewModel.alarmFired
            .subscribe(onNext: { [weak self] alarm in self?.showFiringAlert(for: alarm) })
            .disposed(by: disposeBag)

        tableView.dataSource = self
        tableView.delegate   = self
    }

        // MARK: - Edit Mode
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

        // MARK: - Navigation Bar
    private func setupNavigationBar() {
        title = "알람"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem  = editButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: nil, action: nil
        )

        navigationItem.rightBarButtonItem?.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let vc = AddAlarmViewController()
                vc.onSave = { [weak self] alarm in self?.viewModel.add(alarm) }
                self.present(UINavigationController(rootViewController: vc), animated: true)
            })
            .disposed(by: disposeBag)
    }

        // MARK: - Firing Alert
    private func showFiringAlert(for alarm: AlarmModel) {
        let alert = UIAlertController(
            title:          "\(alarm.ampmString) \(alarm.timeString)",
            message:        alarm.label.isEmpty ? nil : alarm.label,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "끄기", style: .destructive) { [weak self] _ in
            self?.snoozeCountMap.removeValue(forKey: alarm.id)
        })

        if alarm.isSnoozeEnabled {
            let count = snoozeCountMap[alarm.id] ?? 0
            if count < maxSnoozeCount {
                alert.addAction(UIAlertAction(title: "다시 알림", style: .default) { [weak self] _ in
                    guard let self else { return }
                    let menu = UIAlertController(
                        title: "다시 알림", message: "시간을 선택하세요", preferredStyle: .actionSheet
                    )
                    self.snoozeOptions.forEach { option in
                        menu.addAction(UIAlertAction(title: option.label, style: .default) { [weak self] _ in
                            guard let self else { return }
                            self.snoozeCountMap[alarm.id] = count + 1
                            self.viewModel.scheduleSnooze(alarm: alarm, afterMinutes: option.minutes)
                        })
                    }
                    menu.addAction(UIAlertAction(title: "취소", style: .cancel))
                    self.present(menu, animated: true)
                })
            }
        }

        present(alert, animated: true)
    }
}

    // MARK: - UITableViewDataSource
extension AlarmViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.alarms.value.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell  = tableView.dequeueReusableCell(withIdentifier: AlarmCell.identifier, for: indexPath) as? AlarmCell,
            let alarm = viewModel.alarm(at: indexPath.row)
        else { return UITableViewCell() }

        cell.configure(with: alarm)

            // 토글 변경 → ViewModel 업데이트
        cell.toggle.rx.isOn
            .skip(1)    // configure 시 초기값 이벤트 무시
            .subscribe(onNext: { [weak self] isOn in
                guard let self else { return }
                var updated       = alarm
                updated.isEnabled = isOn
                self.viewModel.update(updated)
            })
            .disposed(by: cell.disposeBag)

        return cell
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        viewModel.delete(at: indexPath.row)
    }
}

    // MARK: - UITableViewDelegate
extension AlarmViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let alarm = viewModel.alarm(at: indexPath.row) else { return }

        let vc = AddAlarmViewController(alarm: alarm)
        vc.onSave   = { [weak self] updated in self?.viewModel.update(updated) }
        vc.onDelete = { [weak self] in self?.viewModel.delete(alarm) }
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat { 80 }

    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
}
