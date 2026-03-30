    //
    //  TimerCell.swift
    //  Check It NOW!
    //

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

    /// 타이머 목록 셀
    ///
    /// - 섹션 0 (실행 중): `bindProgress(timeText:progress:state:)` 로 ViewModel과 연동
    /// - 섹션 1 (최근 항목): `configure(with:)` 만 호출
final class TimerCell: UITableViewCell {

        // MARK: - Reuse

    static let identifier = String(describing: TimerCell.self)

    var disposeBag = DisposeBag()
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        ringLayer.removeAllAnimations()
        setRingProgress(1.0, animated: false)
        setRunning(false)
    }

        // MARK: - UI Components

    private let timeLabel = UILabel().then {
        $0.textColor = .white
        $0.font      = .monospacedDigitSystemFont(ofSize: 48, weight: .thin)
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .regular)
    }

    private let ringContainerView = UIView().then {
        $0.backgroundColor = .clear
    }

    private let ringLayer  = CAShapeLayer()   // 진행 링
    private let trackLayer = CAShapeLayer()   // 배경 트랙

        /// 재생/일시정지 버튼
    private let playButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "play.fill"), for: .normal)
        $0.tintColor          = .systemOrange
        $0.backgroundColor    = .clear
        $0.layer.cornerRadius = 28
    }

        // MARK: - Output

        /// 재생 버튼 탭 이벤트 (TimerListViewController에서 구독)
    var playTapped: Observable<Void> { playButton.rx.tap.asObservable() }

        // MARK: - State

    private var currentProgress: Double = 1.0
    private var isRingSetup = false

        // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle              = .none
        backgroundColor             = .clear
        contentView.backgroundColor = .clear
        setupHierarchy()
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupHierarchy() {
        [timeLabel, titleLabel, ringContainerView].forEach { contentView.addSubview($0) }
        ringContainerView.addSubview(playButton)
    }

    private func setupLayout() {
        ringContainerView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(64)
        }

        playButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(56)
        }

        timeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualTo(ringContainerView.snp.leading).offset(-12)
            $0.top.equalToSuperview().inset(14)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualTo(ringContainerView.snp.leading).offset(-12)
            $0.top.equalTo(timeLabel.snp.bottom).offset(2)
            $0.bottom.equalToSuperview().inset(14)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupRingLayersIfNeeded()
    }

        // MARK: - Configure

        /// 최근 항목 표시용
    func configure(with model: TimerModel) {
        timeLabel.text = model.timeString
        if model.label.isEmpty {
            titleLabel.text      = "타이머"
            titleLabel.textColor = .tertiaryLabel
        } else {
            titleLabel.text      = model.label
            titleLabel.textColor = .secondaryLabel
        }
        setRingProgress(1.0, animated: false)
        setRunning(false)
    }

        /// 실행 중인 타이머 — ViewModel Output과 바인딩
        ///
        /// `TimerState`를 최상위 타입으로 직접 참조 → TimerViewModel 의존 없음
    func bindProgress(
        timeText: Driver<String>,
        progress: Driver<Float>,
        state:    Driver<TimerState>
    ) {
        disposeBag = DisposeBag()

        timeText
            .drive(onNext: { [weak self] text in self?.timeLabel.text = text })
            .disposed(by: disposeBag)

        progress
            .drive(onNext: { [weak self] p in self?.setRingProgress(Double(p)) })
            .disposed(by: disposeBag)

        state
            .drive(onNext: { [weak self] s in self?.setRunning(s == .running) })
            .disposed(by: disposeBag)
    }

        // MARK: - Ring State

    func setRunning(_ isRunning: Bool) {
        let tint: UIColor = isRunning ? .systemOrange : .systemGreen
        let bg: UIColor   = isRunning
        ? UIColor.systemOrange.withAlphaComponent(0.15)
        : UIColor.systemGreen.withAlphaComponent(0.2)
        playButton.tintColor       = tint
        playButton.backgroundColor = bg
        playButton.setImage(UIImage(systemName: isRunning ? "pause.fill" : "play.fill"), for: .normal)
        ringLayer.strokeColor = tint.cgColor
    }

    func setRingProgress(_ progress: Double, animated: Bool = true) {
        currentProgress = progress
            // strokeStart 0→1: 시계방향으로 소진
        let targetStart = CGFloat(max(0, min(1, 1.0 - progress)))

        if animated {
            let anim                   = CABasicAnimation(keyPath: "strokeStart")
            anim.fromValue             = ringLayer.presentation()?.strokeStart ?? ringLayer.strokeStart
            anim.toValue               = targetStart
            anim.duration              = 0.1
            anim.timingFunction        = CAMediaTimingFunction(name: .linear)
            anim.fillMode              = .forwards
            anim.isRemovedOnCompletion = false
            ringLayer.add(anim, forKey: "ringProgress")
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            ringLayer.strokeStart = targetStart
            CATransaction.commit()
        }
    }

        // MARK: - Ring Setup

    private func setupRingLayersIfNeeded() {
        guard !isRingSetup, ringContainerView.bounds.width > 0 else { return }
        isRingSetup = true

        let center          = CGPoint(x: ringContainerView.bounds.midX, y: ringContainerView.bounds.midY)
        let radius: CGFloat = 30
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: CGFloat.pi * 1.5,
            clockwise: true
        )

            // 배경 트랙
        trackLayer.path        = path.cgPath
        trackLayer.fillColor   = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor(white: 0.25, alpha: 1).cgColor
        trackLayer.lineWidth   = 3
        trackLayer.strokeEnd   = 1.0
        ringContainerView.layer.addSublayer(trackLayer)

            // 진행 링
        ringLayer.path        = path.cgPath
        ringLayer.fillColor   = UIColor.clear.cgColor
        ringLayer.strokeColor = UIColor.systemGreen.cgColor
        ringLayer.lineWidth   = 3
        ringLayer.lineCap     = .round
        ringLayer.strokeEnd   = 1.0
        ringContainerView.layer.addSublayer(ringLayer)
    }
}
