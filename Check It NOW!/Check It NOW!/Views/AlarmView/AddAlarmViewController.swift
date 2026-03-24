// AddAlarmViewController.swift
import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class AddAlarmViewController: UIViewController {

    // MARK: - Callback
    var onSave: ((AlarmModel) -> Void)?

    // MARK: - State
    private var alarm: AlarmModel
    private let disposeBag = DisposeBag()

    // MARK: - UI
    private let timePicker = UIDatePicker().then {
        $0.datePickerMode            = .time
        $0.preferredDatePickerStyle  = .wheels
        $0.locale                    = Locale(identifier: "ko_KR")
        $0.overrideUserInterfaceStyle = .dark
    }

    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        $0.dataSource      = self
        $0.delegate        = self
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        $0.register(LabelCell.self,       forCellReuseIdentifier: LabelCell.reuseID)
    }

    // MARK: - Init
    init(alarm: AlarmModel? = nil) {
        if let alarm {
            self.alarm = alarm
        } else {
            let cal   = Calendar.current
            let now   = Date()
            self.alarm = AlarmModel(
                hour: cal.component(.hour,   from: now),
                minute: cal.component(.minute, from: now),
                label: "알람", isEnabled: true, sound: .radar, repeatDays: [])
        }
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        setupNav()
        setupLayout()
        syncPickerToAlarm()
    }

    // MARK: - Setup
    private func setupNav() {
        title = alarm.label == "알람" && onSave != nil ? "알람 추가" : "알람 편집"
        let orange = UIColor(red: 1, green: 0.62, blue: 0.04, alpha: 1)

        let appearance = UINavigationBarAppearance().then {
            $0.configureWithOpaqueBackground()
            $0.backgroundColor         = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            $0.titleTextAttributes     = [.foregroundColor: UIColor.white]
        }
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor            = orange

        let cancelBtn = UIBarButtonItem(title: "취소", style: .plain, target: nil, action: nil)
        let saveBtn   = UIBarButtonItem(title: "저장", style: .done,  target: nil, action: nil)
        saveBtn.setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)], for: .normal)

        navigationItem.leftBarButtonItem  = cancelBtn
        navigationItem.rightBarButtonItem = saveBtn

        // Rx 바인딩
        cancelBtn.rx.tap
            .subscribe(onNext: { [weak self] in self?.dismiss(animated: true) })
            .disposed(by: disposeBag)

        saveBtn.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.onSave?(self.alarm)
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func setupLayout() {
        view.addSubview(timePicker)
        view.addSubview(tableView)

        timePicker.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(200)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(timePicker.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        timePicker.rx.date
            .subscribe(onNext: { [weak self] date in
                let c = Calendar.current.dateComponents([.hour,.minute], from: date)
                self?.alarm.hour   = c.hour   ?? 0
                self?.alarm.minute = c.minute ?? 0
            })
            .disposed(by: disposeBag)
    }

    private func syncPickerToAlarm() {
        var comps = DateComponents()
        comps.hour = alarm.hour; comps.minute = alarm.minute
        if let d = Calendar.current.date(from: comps) { timePicker.date = d }
    }

    // MARK: - Sections
    enum Row { case `repeat`, label, sound, snooze }
    let rows: [Row] = [.repeat, .label, .sound, .snooze]
}

// MARK: - UITableViewDataSource
extension AddAlarmViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? rows.count : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 삭제 섹션
        if indexPath.section == 1 {
            return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath).then {
                $0.textLabel?.text          = "알람 삭제"
                $0.textLabel?.textColor     = .systemRed
                $0.textLabel?.textAlignment = .center
                $0.backgroundColor          = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
                $0.selectionStyle           = .default
            }
        }

        let dayNames = ["일","월","화","수","목","금","토"]

        switch rows[indexPath.row] {
        case .repeat:
            let sorted = alarm.repeatDays.sorted()
            var val = "안 함"
            if sorted == [0,1,2,3,4,5,6]  { val = "매일" }
            else if sorted == [1,2,3,4,5]  { val = "주중" }
            else if sorted == [0,6]        { val = "주말" }
            else if !sorted.isEmpty        { val = sorted.map { dayNames[$0] }.joined(separator: " ") }
            return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath).then {
                $0.textLabel?.text              = "반복"
                $0.textLabel?.textColor         = .white
                $0.detailTextLabel?.text        = val
                $0.detailTextLabel?.textColor   = UIColor(white: 0.5, alpha: 1)
                $0.accessoryType                = .disclosureIndicator
                $0.backgroundColor              = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
            }

        case .label:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: LabelCell.reuseID, for: indexPath) as? LabelCell else {
                return UITableViewCell()
            }
            cell.configure(text: alarm.label) { [weak self] in self?.alarm.label = $0 }
            return cell

        case .sound:
            return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath).then {
                $0.textLabel?.text              = "사운드"
                $0.textLabel?.textColor         = .white
                $0.detailTextLabel?.text        = alarm.sound.displayName
                $0.detailTextLabel?.textColor   = UIColor(white: 0.5, alpha: 1)
                $0.accessoryType                = .disclosureIndicator
                $0.backgroundColor              = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
            }

        case .snooze:
            return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath).then {
                $0.textLabel?.text  = "다시 알림"
                $0.textLabel?.textColor = .white
                $0.selectionStyle   = .none
                $0.backgroundColor  = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
                $0.accessoryView    = UISwitch().then {
                    $0.isOn        = true
                    $0.onTintColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { nil }
}

// MARK: - UITableViewDelegate
extension AddAlarmViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 1 {
            dismiss(animated: true)
            return
        }

        switch rows[indexPath.row] {
        case .repeat:
            let vc = RepeatDayViewController(selected: alarm.repeatDays) { [weak self] days in
                self?.alarm.repeatDays = days
                tableView.reloadRows(at: [indexPath], with: .none)
            }
            navigationController?.pushViewController(vc, animated: true)

        case .sound:
            let vc = SoundPickerViewController(selected: alarm.sound) { [weak self] sound in
                self?.alarm.sound = sound
                tableView.reloadRows(at: [indexPath], with: .none)
            }
            navigationController?.pushViewController(vc, animated: true)

        default: break
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
    }
}

// MARK: - LabelCell
final class LabelCell: UITableViewCell, UITextFieldDelegate {
    static let reuseID = "LabelCell"
    private var onChange: ((String) -> Void)?

    private let titleLabel = UILabel().then {
        $0.text      = "레이블"
        $0.textColor = .white
        $0.font      = .systemFont(ofSize: 17)
    }

    private let textField = UITextField().then {
        $0.textAlignment     = .right
        $0.textColor         = UIColor(white: 0.5, alpha: 1)
        $0.font              = .systemFont(ofSize: 17)
        $0.returnKeyType     = .done
        $0.keyboardAppearance = .dark
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor    = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        selectionStyle     = .none
        textField.delegate = self

        let stack = UIStackView(arrangedSubviews: [titleLabel, textField]).then {
            $0.axis    = .horizontal
            $0.spacing = 8
        }
        contentView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().inset(12)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String, onChange: @escaping (String) -> Void) {
        textField.text  = text
        self.onChange   = onChange
        textField.addTarget(self, action: #selector(edited), for: .editingChanged)
    }

    @objc private func edited() { onChange?(textField.text ?? "") }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }
}
