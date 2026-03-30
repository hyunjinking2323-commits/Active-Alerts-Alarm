    //
    //  CircularProgressView.swift
    //  Check It NOW!
    //

import UIKit
import RxSwift
import RxCocoa

    /// 원형 진행 바 커스텀 뷰
    ///
    /// - `trackLayer`: 항상 꽉 찬 어두운 배경 원
    /// - `progressLayer`: 시계방향으로 줄어드는 진행 원
final class CircularProgressView: UIView {

        // MARK: - Appearance

    var trackColor: UIColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1) {
        didSet { trackLayer.strokeColor = trackColor.cgColor }
    }

    var progressColor: UIColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1) {
        didSet { progressLayer.strokeColor = progressColor.cgColor }
    }

        // MARK: - CAShapeLayer

    private let trackLayer    = CAShapeLayer()  // 뒤 — 배경 원
    private let progressLayer = CAShapeLayer()  // 앞 — 진행 원

    private var isLayerSetup     = false
    private var currentProgress: Float = 1.0

        // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }
        if !isLayerSetup {
            layer.addSublayer(trackLayer)     // 먼저 추가 → 뒤에 렌더링
            layer.addSublayer(progressLayer)  // 나중에 추가 → 앞에 렌더링
            isLayerSetup = true
        }
        updatePaths()
    }

        // MARK: - Private

    private func updatePaths() {
        let center     = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius     = bounds.width / 2 - 14
        let startAngle = -CGFloat.pi / 2          // 12시 방향 시작
        let endAngle   = startAngle + 2 * CGFloat.pi

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        [trackLayer, progressLayer].forEach {
            $0.path      = path.cgPath
            $0.fillColor = UIColor.clear.cgColor
            $0.lineWidth = 10
            $0.lineCap   = .round
        }

        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.strokeEnd   = 1.0

        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.strokeStart = 0

        setProgress(currentProgress, animated: false)
    }

        // MARK: - Public

        /// 진행률 설정
        ///
        /// - Parameters:
        ///   - value: 1.0 = 꽉 참, 0.0 = 완전히 빔
        ///   - animated: 애니메이션 여부
    func setProgress(_ value: Float, animated: Bool = true) {
        currentProgress = value
            // strokeStart를 0→1로 늘려 시계방향으로 소진
        let targetStart = CGFloat(max(0, min(1, 1.0 - value)))

        if animated {
            let anim                   = CABasicAnimation(keyPath: "strokeStart")
            anim.fromValue             = progressLayer.presentation()?.strokeStart ?? progressLayer.strokeStart
            anim.toValue               = targetStart
            anim.duration              = 0.08
            anim.timingFunction        = CAMediaTimingFunction(name: .linear)
            anim.fillMode              = .forwards
            anim.isRemovedOnCompletion = false
            progressLayer.add(anim, forKey: "progress")
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressLayer.strokeStart = targetStart
            CATransaction.commit()
        }
    }
}

    // MARK: - Reactive Extension

extension Reactive where Base: CircularProgressView {
        /// RxSwift Driver 바인딩용 Binder
    var progress: Binder<Float> {
        Binder(base) { view, value in
            view.setProgress(value)
        }
    }
}
