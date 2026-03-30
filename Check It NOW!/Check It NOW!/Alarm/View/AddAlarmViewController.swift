    //
    //  AddAlarmViewController.swift
    //  Check It NOW!
    //

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

    // MARK: - Section

private enum Section: Int, CaseIterable {
    case timePicker
    case options
}

    // MARK: - OptionRow

private enum OptionRow: Int, CaseIterable {
    case repeatDays
    case label
    case sound
    case snooze
    case snoozeInterval   // 스누즈 ON일 때만 표시
}

    // MARK: - AddAlarmViewController

final class AddAlarmViewController: UIViewController {

        // MARK: - Callbacks

    var onSave:   ((AlarmModel) -> Void)?
    var onDelete: (() -> Void)?

        // MARK: - Properties

    private let disposeBag = DisposeBag()
    private var alarm: AlarmModel

        /// 스누즈 토글 변경 시 `snoozeInterval` 행을 동적으로 삽입/삭제
    private var isSnoozeEnabled: Bool {
        didSet {
            alarm.isSnoozeEnabled = isSnoozeEnabled
            updateSnoozeIntervalRow()
        }
    }

        /// 스누즈가 켜져 있을 때만 snoozeInterval 행을 포함
    private var visibleOptionRows: [OptionRow] {
        OptionRow.allCases.filter { $0 != .snoozeInterval || isSnoozeEnabled }
    }

        // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        $0.separatorColor  = UIColor(white: 0.25, alpha: 1)
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "OptionCell")
    }

    private let cancelButton = UIBarButtonItem(title: "취소", style: .plain, target: nil, action: nil).then {
        $0.tintColor = .systemOrange
    }

    private let saveButton = UIBarButtonItem(title: "저장", style: .done, target: nil, action: nil).then {
        $0.tintColor = .systemOrange
    }

    private let timePicker = UIDatePicker().then {
        $0.datePickerMode              = .time
        $0.preferredDatePickerStyle    = .wheels
        $0.locale                      = Locale(identifier: "ko_KR")
        $0.overrideUserInterfaceStyle  = .dark
    }

        // MARK: - Init

        /// 새 알람 추가
    init() {
        alarm            = AlarmModel()
        isSnoozeEnabled  = true
        super.init(nibName: nil, bundle: nil)
    }

        /// 기존 알람 편집
    init(alarm: AlarmModel) {
        self.alarm       = alarm
        isSnoozeEnabled  = alarm.isSnoozeEnabled
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        setupHierarchy()
        setupLayout()
        configureUI()
        bind()
    }

    private func setupHierarchy() {
        view.addSubview(tableView)
    }

    private func setupLayout() {
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func configureUI() {
        tableView.register(LabelCell.self, forCellReuseIdentifier: LabelCell.identifier)
        title = alarm.label.isEmpty ? "알람 추가" : "알람 편집"
        navigationItem.leftBarButtonItem  = cancelButton
        navigationItem.rightBarButtonItem = saveButton
    }

    private func bind() {
        tableView.delegate   = self
        tableView.dataSource = self
        timePicker.date      = alarm.time

            // 취소 → 닫기
        cancelButton.rx.tap
            .bind(with: self) { owner, _ in owner.dismiss(animated: true) }
            .disposed(by: disposeBag)

            // 저장 → 콜백 호출 후 닫기
        saveButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.alarm.time = owner.timePicker.date
                owner.onSave?(owner.alarm)
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }

        // MARK: - Private

        /// 스누즈 토글 변경 시 snoozeInterval 행 애니메이션 삽입/삭제
    private func updateSnoozeIntervalRow() {
        let ip = IndexPath(row: OptionRow.snoozeInterval.rawValue, section: Section.options.rawValue)
        tableView.beginUpdates()
        if isSnoozeEnabled {
            tableView.insertRows(at: [ip], with: .fade)
        } else {
            tableView.deleteRows(at: [ip], with: .fade)
        }
        tableView.endUpdates()
    }
}

    // MARK: - UITableViewDataSource

extension AddAlarmViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
            case .timePicker: return 1
            case .options:    return visibleOptionRows.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
            case .timePicker: return makeTimePickerCell()
            case .options:    return makeOptionCell(for: visibleOptionRows[indexPath.row], at: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Section(rawValue: indexPath.section) == .timePicker ? 220 : 50
    }

        // MARK: Cell Factories

    private func makeTimePickerCell() -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        cell.selectionStyle  = .none
        cell.contentView.addSubview(timePicker)
        timePicker.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }
        return cell
    }

    private func makeOptionCell(for row: OptionRow, at indexPath: IndexPath) -> UITableViewCell {
            // LabelCell은 별도 레이아웃이므로 early return
        if row == .label {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: LabelCell.identifier, for: indexPath
            ) as! LabelCell
            cell.textField.text = alarm.label
            cell.textField.rx.text.orEmpty
                .skip(1)
                .bind(with: self) { owner, text in
                    owner.alarm.label = text.trimmingCharacters(in: .whitespaces)
                }
                .disposed(by: cell.disposeBag)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
        cell.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        cell.accessoryType   = .disclosureIndicator
        cell.tintColor       = .systemOrange

        var config = cell.defaultContentConfiguration()
        config.textProperties.color = .white

        switch row {
            case .repeatDays:
                config.text = "반복"
                config.secondaryText = alarm.repeatText
                config.secondaryTextProperties.color = .systemOrange

            case .label:
                break // 위에서 처리됨

            case .sound:
                config.text = "알람 소리"
                config.secondaryText = alarm.soundName
                config.secondaryTextProperties.color = .systemOrange

            case .snooze:
                config.text = "다시 알림"
                cell.accessoryType = .none
                let sw = UISwitch()
                sw.isOn        = isSnoozeEnabled
                sw.onTintColor = .systemGreen
                sw.addAction(UIAction { [weak self] action in
                    guard let self, let s = action.sender as? UISwitch else { return }
                    self.isSnoozeEnabled = s.isOn
                }, for: .valueChanged)
                cell.accessoryView = sw

            case .snoozeInterval:
                config.text = "다시 알림 연기 시간"
                config.secondaryText = alarm.snoozeIntervalText
                config.secondaryTextProperties.color = .systemOrange
        }

        cell.contentConfiguration = config
        return cell
    }
}

    // MARK: - UITableViewDelegate

extension AddAlarmViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Section(rawValue: indexPath.section) == .options else { return }

        switch visibleOptionRows[indexPath.row] {
            case .repeatDays:
                let vc = RepeatDayViewController(selectedDays: alarm.repeatDays)
                vc.delegate = self
                navigationController?.pushViewController(vc, animated: true)

            case .label:
                if let row = visibleOptionRows.firstIndex(of: .label) {
                    let ip = IndexPath(row: row, section: Section.options.rawValue)
                    (tableView.cellForRow(at: ip) as? LabelCell)?.textField.becomeFirstResponder()
                }

            case .sound:
                let vc = SoundPickerViewController(
                    selected: AlarmSound.from(name: alarm.soundName)
                ) { [weak self] sound in
                    self?.alarm.soundName       = sound.displayName
                    self?.alarm.selectedSoundID = sound.systemSoundID
                    self?.tableView.reloadRows(
                        at: [IndexPath(row: OptionRow.sound.rawValue, section: Section.options.rawValue)],
                        with: .none
                    )
                }
                navigationController?.pushViewController(vc, animated: true)

            case .snooze:
                break

            case .snoozeInterval:
                let vc = RepeatIntervalViewController(currentInterval: alarm.snoozeInterval)
                vc.delegate = self
                navigationController?.pushViewController(vc, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == Section.timePicker.rawValue ? 20 : UITableView.automaticDimension
    }

        /// 삭제 버튼 — 편집 모드에서만 표시 (onDelete != nil)
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == Section.options.rawValue, onDelete != nil else { return nil }
        let button = UIButton(type: .system).then {
            $0.setTitle("알람 삭제", for: .normal)
            $0.setTitleColor(.systemRed, for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 17)
        }
        button.rx.tap
            .bind(with: self) { owner, _ in
                owner.onDelete?()
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        let container = UIView()
        container.addSubview(button)
        button.snp.makeConstraints { $0.center.equalToSuperview() }
        return container
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == Section.options.rawValue && onDelete != nil ? 60 : 0
    }
}

    // MARK: - RepeatDayViewControllerDelegate

extension AddAlarmViewController: RepeatDayViewControllerDelegate {
    func didSelectRepeatDays(_ days: [Int]) {
        alarm.repeatDays = days
        guard let row = visibleOptionRows.firstIndex(of: .repeatDays) else { return }
        tableView.reloadRows(at: [IndexPath(row: row, section: Section.options.rawValue)], with: .none)
    }
}

    // MARK: - RepeatIntervalViewControllerDelegate

extension AddAlarmViewController: RepeatIntervalViewControllerDelegate {
    func didSelectInterval(_ minutes: Int) {
        alarm.snoozeInterval = minutes
        guard let row = visibleOptionRows.firstIndex(of: .snoozeInterval) else { return }
        tableView.reloadRows(at: [IndexPath(row: row, section: Section.options.rawValue)], with: .none)
    }
}
