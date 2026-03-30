    //
    //  TimerViewController.swift
    //  Check It NOW!
    //

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class TimerViewController: UIViewController {

        // MARK: - Properties

    private let disposeBag  = DisposeBag()
    private let viewModel:    TimerViewModel
    private let initialLabel: String

        // MARK: - Input Relays

    private let startPauseRelay      = PublishRelay<Void>()
    private let cancelRelay          = PublishRelay<Void>()
    private let selectedSecondsRelay = PublishRelay<Double>()
    private let labelTextRelay       = PublishRelay<String>()
    private let openSoundPickerRelay = PublishRelay<Void>()
    private let selectedSoundIDRelay = PublishRelay<Int>()

        // MARK: - UI: 진행 화면

    private let progressView = CircularProgressView()

    private let timeLabel = UILabel().then {
        $0.text                      = "00:00"
        $0.textColor                 = .white
        $0.font                      = .monospacedDigitSystemFont(ofSize: 80, weight: .thin)
        $0.textAlignment             = .center
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor        = 0.5
    }

    private let endTimeLabel = UILabel().then {
        $0.textColor     = UIColor(white: 0.6, alpha: 1)
        $0.font          = .systemFont(ofSize: 16)
        $0.textAlignment = .center
    }

        // MARK: - UI: 버튼

    private let cancelButton = UIButton(type: .system).then {
        $0.setTitle("취소", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor    = UIColor(white: 0.28, alpha: 1)
        $0.titleLabel?.font   = .systemFont(ofSize: 18, weight: .semibold)
        $0.layer.cornerRadius = 40
    }

    private let startPauseButton = UIButton(type: .system).then {
        $0.setTitle("일시정지", for: .normal)
        $0.setTitleColor(UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1), for: .normal)
        $0.backgroundColor    = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 0.25)
        $0.titleLabel?.font   = .systemFont(ofSize: 18, weight: .semibold)
        $0.layer.cornerRadius = 40
    }

        // MARK: - UI: 소리 선택 시트

    private let dimmedView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        $0.alpha           = 0
    }
    private let soundPickerSheet           = SoundPickerSheetView()
    private var soundSheetBottomConstraint: Constraint?
    private let soundSheetHeight: CGFloat  = 400

        // MARK: - UI: 종료 오버레이

    private let finishView = TimerFinishView()

        // MARK: - Init

    init(viewModel: TimerViewModel, seconds: Double = 60, label: String = "") {
        self.viewModel    = viewModel
        self.initialLabel = label
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) { fatalError() }

        // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupHierarchy()
        setupLayout()
        configureUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
            // 스와이프로 목록으로 돌아올 수 있도록 인터랙티브 팝 활성화
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate  = nil
    }

        // MARK: - Setup Hierarchy

    private func setupHierarchy() {
        [progressView, cancelButton, startPauseButton,
         dimmedView, soundPickerSheet, finishView].forEach { view.addSubview($0) }
        [timeLabel, endTimeLabel].forEach { progressView.addSubview($0) }
        finishView.isHidden = true
    }

        // MARK: - Setup Layout

    private func setupLayout() {
        progressView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(view.safeAreaLayoutGuide).multipliedBy(0.82)
            $0.width.height.equalTo(280)
        }
        timeLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        endTimeLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(timeLabel.snp.bottom).offset(8)
        }
        cancelButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(48)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(30)
            $0.width.height.equalTo(80)
        }
        startPauseButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(48)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(30)
            $0.width.height.equalTo(80)
        }
        dimmedView.snp.makeConstraints { $0.edges.equalToSuperview() }
        soundPickerSheet.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(soundSheetHeight)
            soundSheetBottomConstraint = $0.bottom.equalTo(view.snp.bottom)
                .offset(soundSheetHeight).constraint
        }
        finishView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

        // MARK: - Configure UI

    private func configureUI() {
        progressView.trackColor    = UIColor(white: 0.17, alpha: 1)
        progressView.progressColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
        progressView.setProgress(1.0, animated: false)
    }

        // MARK: - Bind

    private func bind() {
        let input = TimerViewModel.Input(
            startPause:      startPauseRelay,
            cancel:          cancelRelay,
            selectedSeconds: selectedSecondsRelay,
            labelText:       labelTextRelay,
            openSoundPicker: openSoundPickerRelay,
            selectedSoundID: selectedSoundIDRelay,
            deleteTimer:     PublishRelay<UUID>()
        )
        let output = viewModel.transform(input: input)

        labelTextRelay.accept(initialLabel)

        bindButtons()
        bindOutputs(output: output)
    }
}

    // MARK: - Bind Buttons

private extension TimerViewController {

    func bindButtons() {
        startPauseButton.rx.tap
            .bind(to: startPauseRelay)
            .disposed(by: disposeBag)

        cancelButton.rx.tap
            .bind(to: cancelRelay)
            .disposed(by: disposeBag)

        soundPickerSheet.selectedSoundID
            .bind(to: selectedSoundIDRelay)
            .disposed(by: disposeBag)

            // dimmedView 탭 → 소리 시트 닫기
        let dimTap = UITapGestureRecognizer()
        dimmedView.addGestureRecognizer(dimTap)
        dimTap.rx.event
            .map { _ in }
            .bind(to: openSoundPickerRelay)
            .disposed(by: disposeBag)
    }
}

    // MARK: - Bind Outputs

private extension TimerViewController {

    func bindOutputs(output: TimerViewModel.Output) {
        output.timeText
            .drive(timeLabel.rx.text)
            .disposed(by: disposeBag)

        output.endTimeText
            .drive(endTimeLabel.rx.text)
            .disposed(by: disposeBag)

        output.progress
            .drive(progressView.rx.progress)
            .disposed(by: disposeBag)

        output.buttonTitle
            .drive(startPauseButton.rx.title())
            .disposed(by: disposeBag)

        output.selectedSoundID
            .drive(onNext: { [weak self] id in
                self?.soundPickerSheet.currentSelectedID = id
            })
            .disposed(by: disposeBag)

        output.availableSounds
            .drive(onNext: { [weak self] sounds in
                self?.soundPickerSheet.sounds = sounds
            })
            .disposed(by: disposeBag)

        output.isSoundPickerVisible
            .drive(onNext: { [weak self] visible in
                self?.animateSoundSheet(visible: visible)
            })
            .disposed(by: disposeBag)

            // TimerState 최상위 타입 직접 참조
        output.timerState
            .drive(onNext: { [weak self] state in
                guard let self else { return }
                updateButtonStyle(for: state)

                if state == .finished {
                    finishView.isHidden = false
                    finishView.startCountdown(seconds: 30)
                    finishView.onCancel = { [weak self] in
                        self?.finishView.isHidden = true
                        self?.finishView.stopCountdown()
                        self?.cancelRelay.accept(())
                    }
                    finishView.onConfirm = { [weak self] in
                        self?.finishView.isHidden = true
                        self?.finishView.stopCountdown()
                        self?.cancelRelay.accept(())
                    }
                } else {
                    finishView.isHidden = true
                    finishView.stopCountdown()
                }
            })
            .disposed(by: disposeBag)
    }
}

    // MARK: - UI Updates

private extension TimerViewController {

    func updateButtonStyle(for state: TimerState) {
        let isPaused = state == .paused
        UIView.animate(withDuration: 0.2) {
            self.startPauseButton.setTitleColor(
                isPaused ? .white : UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1),
                for: .normal
            )
            self.startPauseButton.backgroundColor = isPaused
            ? UIColor(white: 0.28, alpha: 1)
            : UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 0.25)
        }
    }

    func animateSoundSheet(visible: Bool) {
        soundSheetBottomConstraint?.update(offset: visible ? 0 : soundSheetHeight)
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.3,
            options: .curveEaseInOut
        ) {
            self.dimmedView.alpha = visible ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }
}
