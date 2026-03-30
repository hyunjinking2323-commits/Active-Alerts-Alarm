//
//  TimerFinishView.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.27.
//

import UIKit
import SnapKit
import Then

    /// 타이머 종료 시 표시되는 오버레이 뷰
    ///
    /// - X(취소) / ✓(확인) 버튼
    /// - 자동 종료 카운트다운 원형 바 (드래그로 시간 재설정 가능)
final class TimerFinishView: UIView {

        // MARK: - Callbacks

    var onCancel:  (() -> Void)?
    var onConfirm: (() -> Void)?

        // MARK: - UI

    private let cancelButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)), for: .normal)
        $0.tintColor          = .white
        $0.backgroundColor    = UIColor(red: 0.28, green: 0.28, blue: 0.28, alpha: 1)
        $0.layer.cornerRadius = 40
    }

    private let confirmButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "checkmark",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)), for: .normal)
        $0.tintColor          = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
        $0.backgroundColor    = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 0.25)
        $0.layer.cornerRadius = 40
    }

        // MARK: - Ring Layers

        /// 배경 트랙 레이어
    private let countdownTrackLayer = CAShapeLayer()
        /// 카운트다운 진행 레이어
    private let countdownRingLayer  = CAShapeLayer()

    private let countdownLabel = UILabel().then {
        $0.textColor     = UIColor(white: 0.6, alpha: 1)
        $0.font          = .systemFont(ofSize: 13)
        $0.textAlignment = .center
    }

    private let ringContainerView = UIView()

        // MARK: - State

    private var totalAutoStopSeconds: Int = 30
    private var remainingAutoStop:    Int = 30

        /// Timer는 RunLoop에 강한 참조를 가짐
        /// → invalidate() 없이 뷰가 해제되면 retain cycle 발생
        /// → deinit에서 반드시 invalidate() 호출
    private var countdownTimer: Timer?

        // 링 드래그용
    private var isDragging:     Bool    = false
    private var dragStartAngle: CGFloat = 0
    private var dragStartValue: CGFloat = 0

        // 링 레이어가 한 번만 추가되도록 방지하는 플래그
    private var isRingSetup = false

        // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Deinit

        /// Timer는 RunLoop에 등록되어 있어 invalidate() 없이는 해제되지 않음
        /// → deinit에서 반드시 중지해 메모리 누수 방지
    deinit {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

        // MARK: - Public

        /// 카운트다운 시작 — 타이머 종료 시 호출
    func startCountdown(seconds: Int) {
        totalAutoStopSeconds = seconds
        remainingAutoStop    = seconds
        updateCountdownLabel()
        setRingProgress(1.0, animated: false)
        startTimer()
    }

        /// 카운트다운 중지 — 뷰 숨김 또는 버튼 탭 시 호출
    func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

        // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        setupRingLayersIfNeeded()
    }
}

    // MARK: - Setup

private extension TimerFinishView {

    func setup() {
        backgroundColor = UIColor.black.withAlphaComponent(0.85)

        ringContainerView.addSubview(countdownLabel)
        [ringContainerView, cancelButton, confirmButton].forEach { addSubview($0) }

        ringContainerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(120)
        }
        countdownLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        cancelButton.snp.makeConstraints {
            $0.trailing.equalTo(ringContainerView.snp.leading).offset(-40)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(80)
        }
        confirmButton.snp.makeConstraints {
            $0.leading.equalTo(ringContainerView.snp.trailing).offset(40)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(80)
        }

        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

            // 링 드래그로 자동 종료 시간 재설정
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleRingPan(_:)))
        ringContainerView.addGestureRecognizer(pan)
    }

        /// bounds가 확정된 이후 한 번만 레이어를 설정
        /// layoutSubviews는 여러 번 호출될 수 있으므로 isRingSetup 플래그로 중복 추가 방지
    func setupRingLayersIfNeeded() {
        guard !isRingSetup, ringContainerView.bounds.width > 0 else { return }
        isRingSetup = true

        let center = CGPoint(x: ringContainerView.bounds.midX,
                             y: ringContainerView.bounds.midY)
        let path = UIBezierPath(
            arcCenter: center,
            radius: 46,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        )

        [countdownTrackLayer, countdownRingLayer].forEach {
            $0.path      = path.cgPath
            $0.fillColor = UIColor.clear.cgColor
            $0.lineWidth = 6
            $0.lineCap   = .round
        }

        countdownTrackLayer.strokeColor = UIColor(white: 0.25, alpha: 1).cgColor
        countdownTrackLayer.strokeEnd   = 1.0

        countdownRingLayer.strokeColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1).cgColor
        countdownRingLayer.strokeEnd   = 1.0

            // 트랙을 먼저, 링을 나중에 추가해 링이 위에 렌더링되도록 설정
        ringContainerView.layer.addSublayer(countdownTrackLayer)
        ringContainerView.layer.addSublayer(countdownRingLayer)
    }

        /// value: 1.0 = 꽉 참, 0.0 = 빔
        /// strokeStart 0 → 1 방향으로 시계방향 소진
    func setRingProgress(_ value: CGFloat, animated: Bool) {
        let target = 1.0 - value
        if animated {
            let anim                   = CABasicAnimation(keyPath: "strokeStart")
            anim.fromValue             = countdownRingLayer.presentation()?.strokeStart
            ?? countdownRingLayer.strokeStart
            anim.toValue               = target
            anim.duration              = 0.3
            anim.fillMode              = .forwards
            anim.isRemovedOnCompletion = false
            countdownRingLayer.add(anim, forKey: "ring")
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            countdownRingLayer.strokeStart = target
            CATransaction.commit()
        }
    }

    func updateCountdownLabel() {
        countdownLabel.text = "\(remainingAutoStop)초"
    }

    func startTimer() {
            // 이미 실행 중인 타이머가 있으면 먼저 중지
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            remainingAutoStop -= 1
            updateCountdownLabel()
            let progress = CGFloat(remainingAutoStop) / CGFloat(totalAutoStopSeconds)
            setRingProgress(progress, animated: true)

            if remainingAutoStop <= 0 {
                stopCountdown()
                onConfirm?()  // 시간 초과 → 자동 확인 처리
            }
        }
    }
}

    // MARK: - Actions

private extension TimerFinishView {

    @objc func cancelTapped()  { onCancel?() }
    @objc func confirmTapped() { onConfirm?() }

        /// 링 드래그로 자동 종료 시간 재설정
    @objc func handleRingPan(_ gesture: UIPanGestureRecognizer) {
        let center   = CGPoint(x: ringContainerView.bounds.midX,
                               y: ringContainerView.bounds.midY)
        let location = gesture.location(in: ringContainerView)
        let angle    = atan2(location.y - center.y, location.x - center.x)

        switch gesture.state {
            case .began:
                isDragging     = true
                dragStartAngle = angle
                dragStartValue = CGFloat(remainingAutoStop) / CGFloat(totalAutoStopSeconds)

            case .changed:
                var delta = angle - dragStartAngle
                    // 각도 wrap-around 처리 (-π ~ π 범위로 정규화)
                if delta >  .pi { delta -= 2 * .pi }
                if delta < -.pi { delta += 2 * .pi }

                let newValue   = max(0, min(1, dragStartValue - delta / (2 * .pi)))
                let newSeconds = Int(newValue * CGFloat(totalAutoStopSeconds))
                remainingAutoStop = max(1, newSeconds)
                updateCountdownLabel()
                setRingProgress(newValue, animated: false)

            case .ended, .cancelled:
                isDragging = false
                    // 드래그 후 새 남은 시간 기준으로 타이머 재시작
                stopCountdown()
                startTimer()

            default:
                break
        }
    }
}
