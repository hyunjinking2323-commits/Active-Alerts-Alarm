import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class AddAlarmViewController: BaseViewController {

        // MARK: - [데이터 전달 콜백]
    var onSave:   ((AlarmModel) -> Void)?
    var onDelete: (() -> Void)?

        // MARK: - [상태 및 데이터]
    private var alarm: AlarmModel
    private let isEditingAlarm: Bool

        // 테이블뷰 섹션 구성을 위한 열거형
    enum Row: CaseIterable { case `repeat`, label, sound, snooze }
    private let rows = Row.allCases

        // MARK: - [초기화]
    init(alarm: AlarmModel? = nil) {
        self.isEditingAlarm = alarm != nil
        if let alarm = alarm {
            self.alarm = alarm
        } else {
                // 새 알람 추가 시 초기값 (현재 시간 기준)
            let now = Date()
            let cal = Calendar.current
            self.alarm = AlarmModel(
                hour: cal.component(.hour, from: now),
                minute: cal.component(.minute, from: now),
                label: "알람", isEnabled: true, sound: .radar, repeatDays: [],
                isSnoozeEnabled: true
            )
        }
        super.init()
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - [UI 컴포넌트 선언]
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
        $0.register(LabelCell.self,       forCellReuseIdentifier: LabelCell.identifier)
    }

        // MARK: - [계층 구조 설정 - BaseViewController 오버라이드]
    override func setupHierarchy() {
        view.addSubview(timePicker)
        view.addSubview(tableView)
    }

        // MARK: - [레이아웃 설정 - BaseViewController 오버라이드]
    override func setupLayout() {
        timePicker.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(200)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(timePicker.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

        // MARK: - [바인딩 및 초기 설정 - BaseViewController 오버라이드]
    override func bind() {
        setupNavigationBar()
        syncPickerToAlarm()

            // 시간 변경 시 데이터 업데이트
        timePicker.rx.date
            .subscribe(onNext: { [weak self] date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                self?.alarm.hour   = c.hour   ?? 0
                self?.alarm.minute = c.minute ?? 0
            })
            .disposed(by: disposeBag)
    }

        // MARK: - [네비게이션 바 설정]
    private func setupNavigationBar() {
        title = isEditingAlarm ? "알람 편집" : "알람 추가"
        let orange = UIColor.systemOrange

        let appearance = UINavigationBarAppearance().then {
            $0.configureWithOpaqueBackground()
            $0.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor            = orange

        let cancelBtn = UIBarButtonItem(title: "취소", style: .plain, target: nil, action: nil)
        let saveBtn   = UIBarButtonItem(title: "저장", style: .done,  target: nil, action: nil)

        navigationItem.leftBarButtonItem  = cancelBtn
        navigationItem.rightBarButtonItem = saveBtn

            // 취소: 화면 닫기
        cancelBtn.rx.tap
            .subscribe(onNext: { [weak self] in self?.dismiss(animated: true) })
            .disposed(by: disposeBag)

            // 저장: 데이터 전달 후 닫기
        saveBtn.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.onSave?(self.alarm)
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func syncPickerToAlarm() {
        var comps = DateComponents()
        comps.hour = alarm.hour
        comps.minute = alarm.minute
        if let date = Calendar.current.date(from: comps) {
            timePicker.date = date
        }
    }
}

    // MARK: - [UITableViewDataSource]
extension AddAlarmViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return isEditingAlarm ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? rows.count : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text          = "알람 삭제"
            cell.textLabel?.textColor     = .systemRed
            cell.textLabel?.textAlignment = .center
            cell.backgroundColor          = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
            return cell
        }

        let dayNames = ["일","월","화","수","목","금","토"]
        switch rows[indexPath.row] {
            case .repeat:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
                cell.textLabel?.text = "반복"
                cell.textLabel?.textColor = .white
                cell.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
                cell.accessoryType = .disclosureIndicator

                let sorted = alarm.repeatDays.sorted()
                if sorted.isEmpty { cell.detailTextLabel?.text = "안 함" }
                else if sorted.count == 7 { cell.detailTextLabel?.text = "매일" }
                else { cell.detailTextLabel?.text = sorted.map { dayNames[$0] }.joined(separator: " ") }
                return cell

            case .label:
                let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
                cell.configure(text: alarm.label) { [weak self] in self?.alarm.label = $0 }
                return cell

            case .sound:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
                cell.textLabel?.text = "사운드"
                cell.textLabel?.textColor = .white
                cell.detailTextLabel?.text = alarm.sound.displayName
                cell.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
                cell.accessoryType = .disclosureIndicator
                return cell

            case .snooze:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = "다시 알림"
                cell.textLabel?.textColor = .white
                cell.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
                let sw = UISwitch()
                sw.isOn = alarm.isSnoozeEnabled
                sw.onTintColor = .systemGreen
                sw.rx.isOn.subscribe(onNext: { [weak self] in self?.alarm.isSnoozeEnabled = $0 }).disposed(by: disposeBag)
                cell.accessoryView = sw
                return cell
        }
    }
}

    // MARK: - [UITableViewDelegate]
extension AddAlarmViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            onDelete?(); dismiss(animated: true); return
        }

        switch rows[indexPath.row] {
            case .repeat:
                let vc = RepeatDayViewController(selected: alarm.repeatDays) { [weak self] in
                    self?.alarm.repeatDays = $0
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
                navigationController?.pushViewController(vc, animated: true)
            case .sound:
                let vc = SoundPickerViewController(selected: alarm.sound) { [weak self] in
                    self?.alarm.sound = $0
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
                navigationController?.pushViewController(vc, animated: true)
            default: break
        }
    }
}

    // MARK: - [LabelCell: BaseTableViewCell 상속]
final class LabelCell: BaseTableViewCell {
    private var onChange: ((String) -> Void)?
    private let titleLabel = UILabel().then { $0.text = "레이블"; $0.textColor = .white }
    private let textField = UITextField().then {
        $0.textAlignment = .right; $0.textColor = .lightGray; $0.keyboardAppearance = .dark
    }

    override func setupHierarchy() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, textField])
        contentView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    override func configureUI() {
        backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
    }

    func configure(text: String, onChange: @escaping (String) -> Void) {
        textField.text = text
        self.onChange = onChange
        textField.rx.text.orEmpty
            .subscribe(onNext: { [weak self] in self?.onChange?($0) })
            .disposed(by: disposeBag)
    }
}
