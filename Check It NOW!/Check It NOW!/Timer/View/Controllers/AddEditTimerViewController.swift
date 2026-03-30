    //
    //  AddEditTimerViewController.swift
    //  Check It NOW!
    //

import UIKit
import AudioToolbox
import RxSwift
import RxCocoa
import SnapKit
import Then

    // MARK: - Delegate

protocol AddEditTimerViewControllerDelegate: AnyObject {
    func didSaveTimer(_ timer: TimerModel)
}

    // MARK: - Mode

enum AddEditTimerMode {
    case add
    case edit(TimerModel)
}

    // MARK: - AddEditTimerViewController

final class AddEditTimerViewController: UIViewController {

        // MARK: - Properties

    private let disposeBag = DisposeBag()
    private let mode: AddEditTimerMode
    weak var delegate: AddEditTimerViewControllerDelegate?

    private var selectedSoundID: Int = 1005
    private var autoStopSeconds: Int = 0   // 0 = 자동 종료 없음

        // MARK: - 사운드 목록

    private let sounds: [SoundModel] = [
        SoundModel(id: 1000, name: "New Mail"),
        SoundModel(id: 1005, name: "Alarm"),
        SoundModel(id: 1007, name: "Tri-tone"),
        SoundModel(id: 1008, name: "Chime"),
        SoundModel(id: 1009, name: "Glass"),
        SoundModel(id: 1010, name: "Horn")
    ]

        // MARK: - UI: 피커 단위 레이블

    private let pickerUnitStackView = UIStackView().then {
        $0.axis = .horizontal; $0.distribution = .fillEqually
    }
    private let hourUnitLabel   = makeUnitLabel("시간")
    private let minuteUnitLabel = makeUnitLabel("분")
    private let secondUnitLabel = makeUnitLabel("초")

        // MARK: - UI: 피커

    private let pickerStackView = UIStackView().then {
        $0.axis = .horizontal; $0.distribution = .fillEqually
    }
    private let hourPicker   = UIPickerView()
    private let minutePicker = UIPickerView()
    private let secondPicker = UIPickerView()

        // MARK: - UI: 옵션 그룹

    private let optionGroupView = UIView().then {
        $0.backgroundColor    = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        $0.layer.cornerRadius = 12
        $0.clipsToBounds      = true
    }

        // 레이블 행
    private let labelRowView    = UIView()
    private let labelTitleLabel = UILabel().then {
        $0.text      = "레이블"
        $0.textColor = .white
        $0.font      = .systemFont(ofSize: 17)
    }
    private let labelTextField = UITextField().then {
        $0.textColor       = UIColor(white: 0.5, alpha: 1)
        $0.textAlignment   = .right
        $0.font            = .systemFont(ofSize: 17)
        $0.returnKeyType   = .done
        $0.clearButtonMode = .whileEditing
        $0.attributedPlaceholder = NSAttributedString(
            string: "타이머",
            attributes: [.foregroundColor: UIColor(white: 0.45, alpha: 1)]
        )
    }

    private let rowDivider = UIView().then {
        $0.backgroundColor = UIColor(white: 0.3, alpha: 1)
    }

        // 타이머 종료 시 행
    private let endActionRowView    = UIView()
    private let endActionTitleLabel = UILabel().then {
        $0.text      = "타이머 종료 시"
        $0.textColor = .white
        $0.font      = .systemFont(ofSize: 17)
    }
    private let endActionValueLabel = UILabel().then {
        $0.textColor     = UIColor(white: 0.5, alpha: 1)
        $0.font          = .systemFont(ofSize: 17)
        $0.textAlignment = .right
    }
    private let endActionChevron = UIImageView().then {
        $0.image       = UIImage(systemName: "chevron.right")
        $0.tintColor   = UIColor(white: 0.4, alpha: 1)
        $0.contentMode = .scaleAspectFit
    }

        // MARK: - UI: 소리 선택 시트

    private let dimmedView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        $0.alpha           = 0
    }
    private let soundSheetView              = UIView()
    private var soundSheetBottomConstraint: Constraint?
    private let soundSheetHeight: CGFloat   = 460

    private let sheetHandleBar = UIView().then {
        $0.backgroundColor    = UIColor(white: 0.4, alpha: 1)
        $0.layer.cornerRadius = 2.5
    }
    private let sheetTitleLabel = UILabel().then {
        $0.text          = "타이머 종료 시"
        $0.textColor     = .white
        $0.font          = .systemFont(ofSize: 17, weight: .semibold)
        $0.textAlignment = .center
    }

        // 알람 자동 종료 섹션
    private let autoStopSectionLabel = UILabel().then {
        $0.text      = "알람 자동 종료"
        $0.textColor = UIColor(white: 0.6, alpha: 1)
        $0.font      = .systemFont(ofSize: 13, weight: .medium)
    }
    private let autoStopRowView = UIView().then {
        $0.backgroundColor    = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        $0.layer.cornerRadius = 10
    }
    private let autoStopTitleLabel = UILabel().then {
        $0.text      = "알람 자동 종료"
        $0.textColor = .white
        $0.font      = .systemFont(ofSize: 17)
    }
    private let autoStopValueLabel = UILabel().then {
        $0.textColor     = UIColor(white: 0.5, alpha: 1)
        $0.font          = .systemFont(ofSize: 17)
        $0.textAlignment = .right
    }
    private let autoStopChevron = UIImageView().then {
        $0.image       = UIImage(systemName: "chevron.right")
        $0.tintColor   = UIColor(white: 0.4, alpha: 1)
        $0.contentMode = .scaleAspectFit
    }

        // 소리 선택 테이블
    private let soundSectionLabel = UILabel().then {
        $0.text      = "소리"
        $0.textColor = UIColor(white: 0.6, alpha: 1)
        $0.font      = .systemFont(ofSize: 13, weight: .medium)
    }
    private let soundTableView = UITableView().then {
        $0.backgroundColor = .clear
        $0.separatorColor  = UIColor(white: 0.25, alpha: 1)
        $0.separatorInset  = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        $0.rowHeight       = 48
        $0.isScrollEnabled = false
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "SoundCell")
    }

        // MARK: - UI: 알람 자동 종료 시트

    private let autoStopPickerSheet              = UIView()
    private var autoStopSheetBottomConstraint:   Constraint?
    private let autoStopPickerSheetHeight: CGFloat = 320

    private let autoStopSheetHandle = UIView().then {
        $0.backgroundColor    = UIColor(white: 0.4, alpha: 1)
        $0.layer.cornerRadius = 2.5
    }
    private let autoStopSheetTitle = UILabel().then {
        $0.text          = "알람 자동 종료"
        $0.textColor     = .white
        $0.font          = .systemFont(ofSize: 17, weight: .semibold)
        $0.textAlignment = .center
    }

        /// 선택 가능한 자동 종료 시간 목록 (초 단위)
    private let autoStopOptions: [(label: String, seconds: Int)] = [
        ("없음", 0),
        ("1초", 1), ("2초", 2), ("5초", 5), ("10초", 10), ("15초", 15), ("30초", 30),
        ("1분", 60), ("2분", 120), ("3분", 180), ("5분", 300), ("10분", 600)
    ]
    private let autoStopTableView = UITableView().then {
        $0.backgroundColor = .clear
        $0.separatorColor  = UIColor(white: 0.25, alpha: 1)
        $0.separatorInset  = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        $0.rowHeight       = 48
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "AutoStopCell")
    }

        // MARK: - Init

    init(mode: AddEditTimerMode) {
        self.mode = mode
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

        // MARK: - Setup Hierarchy

    private func setupHierarchy() {
        [hourUnitLabel, minuteUnitLabel, secondUnitLabel]
            .forEach { pickerUnitStackView.addArrangedSubview($0) }
        [hourPicker, minutePicker, secondPicker]
            .forEach { pickerStackView.addArrangedSubview($0) }

        [labelTitleLabel, labelTextField].forEach { labelRowView.addSubview($0) }
        [endActionTitleLabel, endActionValueLabel, endActionChevron].forEach { endActionRowView.addSubview($0) }
        [labelRowView, rowDivider, endActionRowView].forEach { optionGroupView.addSubview($0) }

        [pickerUnitStackView, pickerStackView, optionGroupView].forEach { view.addSubview($0) }

        [autoStopTitleLabel, autoStopValueLabel, autoStopChevron].forEach { autoStopRowView.addSubview($0) }
        [sheetHandleBar, sheetTitleLabel,
         autoStopSectionLabel, autoStopRowView,
         soundSectionLabel, soundTableView].forEach { soundSheetView.addSubview($0) }

        [autoStopSheetHandle, autoStopSheetTitle, autoStopTableView]
            .forEach { autoStopPickerSheet.addSubview($0) }

        [dimmedView, soundSheetView, autoStopPickerSheet].forEach { view.addSubview($0) }
    }

        // MARK: - Setup Layout

    private func setupLayout() {
        pickerUnitStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(20)
        }
        pickerStackView.snp.makeConstraints {
            $0.top.equalTo(pickerUnitStackView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(216)
        }
        optionGroupView.snp.makeConstraints {
            $0.top.equalTo(pickerStackView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

            // 레이블 행
        labelRowView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(52)
        }
        labelTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        labelTextField.snp.makeConstraints {
            $0.leading.equalTo(labelTitleLabel.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        rowDivider.snp.makeConstraints {
            $0.top.equalTo(labelRowView.snp.bottom)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }

            // 타이머 종료 시 행
        endActionRowView.snp.makeConstraints {
            $0.top.equalTo(rowDivider.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(52)
        }
        endActionTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        endActionChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8); $0.height.equalTo(14)
        }
        endActionValueLabel.snp.makeConstraints {
            $0.trailing.equalTo(endActionChevron.snp.leading).offset(-6)
            $0.centerY.equalToSuperview()
        }

        dimmedView.snp.makeConstraints { $0.edges.equalToSuperview() }

            // 소리 시트
        soundSheetView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(soundSheetHeight)
            soundSheetBottomConstraint = $0.bottom.equalTo(view.snp.bottom)
                .offset(soundSheetHeight).constraint
        }
        sheetHandleBar.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(36); $0.height.equalTo(5)
        }
        sheetTitleLabel.snp.makeConstraints {
            $0.top.equalTo(sheetHandleBar.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(24)
        }
        autoStopSectionLabel.snp.makeConstraints {
            $0.top.equalTo(sheetTitleLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
        }
        autoStopRowView.snp.makeConstraints {
            $0.top.equalTo(autoStopSectionLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(52)
        }
        autoStopTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        autoStopChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8); $0.height.equalTo(14)
        }
        autoStopValueLabel.snp.makeConstraints {
            $0.trailing.equalTo(autoStopChevron.snp.leading).offset(-6)
            $0.centerY.equalToSuperview()
        }
        soundSectionLabel.snp.makeConstraints {
            $0.top.equalTo(autoStopRowView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
        }
        soundTableView.snp.makeConstraints {
            $0.top.equalTo(soundSectionLabel.snp.bottom).offset(6)
            $0.leading.trailing.bottom.equalToSuperview()
        }

            // 자동 종료 시트
        autoStopPickerSheet.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(autoStopPickerSheetHeight)
            autoStopSheetBottomConstraint = $0.bottom.equalTo(view.snp.bottom)
                .offset(autoStopPickerSheetHeight).constraint
        }
        autoStopSheetHandle.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(36); $0.height.equalTo(5)
        }
        autoStopSheetTitle.snp.makeConstraints {
            $0.top.equalTo(autoStopSheetHandle.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(24)
        }
        autoStopTableView.snp.makeConstraints {
            $0.top.equalTo(autoStopSheetTitle.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

        // MARK: - Configure UI

    private func configureUI() {
        soundSheetView.backgroundColor     = UIColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 1)
        soundSheetView.layer.cornerRadius  = 16
        soundSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        soundSheetView.clipsToBounds       = true

        autoStopPickerSheet.backgroundColor     = UIColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 1)
        autoStopPickerSheet.layer.cornerRadius  = 16
        autoStopPickerSheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        autoStopPickerSheet.clipsToBounds       = true

        [hourPicker, minutePicker, secondPicker].forEach {
            $0.setValue(UIColor.white, forKeyPath: "textColor")
        }

        soundTableView.delegate      = self
        soundTableView.dataSource    = self
        autoStopTableView.delegate   = self
        autoStopTableView.dataSource = self

        setupNavigationItems()
        setupPickers()
        configureMode()
        updateEndActionLabel()
        updateAutoStopLabel()
    }

        // MARK: - Bind

    private func bind() {
        navigationItem.leftBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in owner.dismiss(animated: true) }
            .disposed(by: disposeBag)

        navigationItem.rightBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in owner.handleSave() }
            .disposed(by: disposeBag)

        labelTextField.rx.controlEvent(.editingDidEndOnExit)
            .bind(with: self) { owner, _ in owner.labelTextField.resignFirstResponder() }
            .disposed(by: disposeBag)

            // 타이머 종료 시 행 탭 → 소리 시트 열기
        let endRowTap = UITapGestureRecognizer()
        endActionRowView.addGestureRecognizer(endRowTap)
        endRowTap.rx.event
            .bind(with: self) { owner, _ in owner.animateSoundSheet(visible: true) }
            .disposed(by: disposeBag)

            // 알람 자동 종료 행 탭 → 자동 종료 시트 열기
        let autoStopTap = UITapGestureRecognizer()
        autoStopRowView.addGestureRecognizer(autoStopTap)
        autoStopTap.rx.event
            .bind(with: self) { owner, _ in
                owner.animateSoundSheet(visible: false)
                owner.animateAutoStopSheet(visible: true)
            }
            .disposed(by: disposeBag)

            // dimmedView 탭 → 모든 시트 닫기
        let dimTap = UITapGestureRecognizer()
        dimmedView.addGestureRecognizer(dimTap)
        dimTap.rx.event
            .bind(with: self) { owner, _ in
                owner.animateSoundSheet(visible: false)
                owner.animateAutoStopSheet(visible: false)
            }
            .disposed(by: disposeBag)
    }
}

    // MARK: - Private Setup

private extension AddEditTimerViewController {

    func setupNavigationItems() {
        let cancelItem = UIBarButtonItem(title: "취소", style: .plain, target: nil, action: nil)
        cancelItem.tintColor = .systemOrange
        let saveItem = UIBarButtonItem(title: "저장", style: .done, target: nil, action: nil)
        saveItem.tintColor = .systemOrange
        navigationItem.leftBarButtonItem  = cancelItem
        navigationItem.rightBarButtonItem = saveItem
    }

    func setupPickers() {
        [hourPicker, minutePicker, secondPicker].forEach {
            $0.delegate = self; $0.dataSource = self
        }
    }

    func configureMode() {
        switch mode {
            case .add:
                navigationItem.title = "타이머 추가"
                minutePicker.selectRow(5, inComponent: 0, animated: false)
            case .edit(let timer):
                navigationItem.title = "타이머 편집"
                let (h, m, s) = components(from: timer.totalSeconds)
                hourPicker.selectRow(h, inComponent: 0, animated: false)
                minutePicker.selectRow(m, inComponent: 0, animated: false)
                secondPicker.selectRow(s, inComponent: 0, animated: false)
                labelTextField.text = timer.label
                selectedSoundID     = timer.selectedSoundID
                autoStopSeconds     = timer.autoStopSeconds ?? 0
                updateAutoStopLabel()
        }
    }

    func updateEndActionLabel() {
        endActionValueLabel.text = sounds.first { $0.id == selectedSoundID }?.name ?? "알림음"
    }

    func updateAutoStopLabel() {
        autoStopValueLabel.text = autoStopOptions.first { $0.seconds == autoStopSeconds }?.label ?? "없음"
    }

    func animateSoundSheet(visible: Bool) {
        soundSheetBottomConstraint?.update(offset: visible ? 0 : soundSheetHeight)
        UIView.animate(withDuration: 0.45, delay: 0,
                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.3) {
            self.dimmedView.alpha = visible ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    func animateAutoStopSheet(visible: Bool) {
        autoStopSheetBottomConstraint?.update(offset: visible ? 0 : autoStopPickerSheetHeight)
        UIView.animate(withDuration: 0.45, delay: 0,
                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.3) {
            self.dimmedView.alpha = visible ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    func handleSave() {
        let h     = hourPicker.selectedRow(inComponent: 0)
        let m     = minutePicker.selectedRow(inComponent: 0)
        let s     = secondPicker.selectedRow(inComponent: 0)
        let total = Double(h * 3600 + m * 60 + s)

        guard total > 0 else {
            let alert = UIAlertController(
                title: "시간을 설정해주세요",
                message: "1초 이상의 시간을 설정해야 합니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        let labelText = labelTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let newTimer: TimerModel

        switch mode {
            case .add:
                newTimer = TimerModel(
                    label: labelText,
                    totalSeconds: total,
                    selectedSoundID: selectedSoundID,
                    autoStopSeconds: autoStopSeconds == 0 ? nil : autoStopSeconds
                )
            case .edit(let existing):
                newTimer = TimerModel(
                    copying: existing,
                    label: labelText,
                    totalSeconds: total,
                    selectedSoundID: selectedSoundID,
                    autoStopSeconds: autoStopSeconds == 0 ? nil : autoStopSeconds
                )
        }

        delegate?.didSaveTimer(newTimer)
        dismiss(animated: true)
    }

    func components(from totalSeconds: Double) -> (Int, Int, Int) {
        let total = Int(totalSeconds)
        return (total / 3600, (total % 3600) / 60, total % 60)
    }

    static func makeUnitLabel(_ text: String) -> UILabel {
        UILabel().then {
            $0.text          = text
            $0.font          = .systemFont(ofSize: 14, weight: .medium)
            $0.textColor     = UIColor(white: 0.6, alpha: 1)
            $0.textAlignment = .center
        }
    }
}

    // MARK: - UITableViewDataSource & Delegate

extension AddEditTimerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === soundTableView     { return sounds.count }
        if tableView === autoStopTableView  { return autoStopOptions.count }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === soundTableView {
            let cell  = tableView.dequeueReusableCell(withIdentifier: "SoundCell", for: indexPath)
            let sound = sounds[indexPath.row]
            cell.textLabel?.text      = sound.name
            cell.textLabel?.textColor = .white
            cell.textLabel?.font      = .systemFont(ofSize: 17)
            cell.backgroundColor      = .clear
            cell.selectionStyle       = .none
            cell.tintColor            = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
            cell.accessoryType        = (sound.id == selectedSoundID) ? .checkmark : .none
            return cell
        }

        if tableView === autoStopTableView {
            let cell   = tableView.dequeueReusableCell(withIdentifier: "AutoStopCell", for: indexPath)
            let option = autoStopOptions[indexPath.row]
            cell.textLabel?.text      = option.label
            cell.textLabel?.textColor = .white
            cell.textLabel?.font      = .systemFont(ofSize: 17)
            cell.backgroundColor      = .clear
            cell.selectionStyle       = .none
            cell.tintColor            = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
            cell.accessoryType        = (option.seconds == autoStopSeconds) ? .checkmark : .none
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === soundTableView {
            selectedSoundID = sounds[indexPath.row].id
            AudioServicesPlaySystemSound(SystemSoundID(selectedSoundID))
            updateEndActionLabel()
            soundTableView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.animateSoundSheet(visible: false)
            }
        }

        if tableView === autoStopTableView {
            autoStopSeconds = autoStopOptions[indexPath.row].seconds
            updateAutoStopLabel()
            autoStopTableView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.animateAutoStopSheet(visible: false)
            }
        }
    }
}

    // MARK: - UIPickerViewDataSource & Delegate

extension AddEditTimerViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
            case hourPicker:   return 24
            case minutePicker: return 60
            case secondPicker: return 60
            default:           return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView,
                    attributedTitleForRow row: Int,
                    forComponent component: Int) -> NSAttributedString? {
        NSAttributedString(
            string: String(format: "%02d", row),
            attributes: [.foregroundColor: UIColor.white]
        )
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 44 }
}
