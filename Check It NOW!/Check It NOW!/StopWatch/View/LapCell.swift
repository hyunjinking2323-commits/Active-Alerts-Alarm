//
//  LapCell.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.23.
//

import UIKit
import Then
import SnapKit
import RxSwift

    /// 스톱워치 랩 기록 셀
final class LapCell: UITableViewCell {

        // MARK: - Reuse

    static let identifier = String(describing: LapCell.self)

    var disposeBag = DisposeBag()
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

        // MARK: - Highlight

        /// 가장 빠른 / 느린 / 일반 랩 구분
    enum Highlight { case fastest, slowest, none }

        // MARK: - UI

    private let lapLabel = UILabel().then {
        $0.font      = .systemFont(ofSize: 17)
        $0.textColor = .white
    }

    private let timeLabel = UILabel().then {
        $0.font          = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)
        $0.textColor     = .white
        $0.textAlignment = .right
    }

        // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle  = .none
        backgroundColor = .black
        setupHierarchy()
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupHierarchy() {
        [lapLabel, timeLabel].forEach { contentView.addSubview($0) }
    }

    private func setupLayout() {
        lapLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }
        timeLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(lapLabel.snp.trailing).offset(8)
        }
    }

        // MARK: - Configure

    func configure(lap: String, time: String, highlight: Highlight = .none) {
        lapLabel.text  = lap
        timeLabel.text = time

        let color: UIColor
        switch highlight {
            case .fastest: color = .systemGreen
            case .slowest: color = .systemRed
            case .none:    color = .white
        }
        lapLabel.textColor  = color
        timeLabel.textColor = color
    }
}
