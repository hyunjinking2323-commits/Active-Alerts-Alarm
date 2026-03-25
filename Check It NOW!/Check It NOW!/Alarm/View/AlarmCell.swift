    //
    //  AlarmCell.swift
    //  Check It NOW!
    //
    //  Created by t2025-m0239 on 2026.03.23.
    //

import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class AlarmCell: UITableViewCell {

    static var identifier: String { String(describing: self) }
    static let reuseID = "AlarmCell"
    var disposeBag = DisposeBag()

        // MARK: - UI
    private let timeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 52, weight: .thin)
        $0.textColor = .white
    }

    private let ampmLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 18, weight: .light)
        $0.textColor = .white
    }

    private let subLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = UIColor(white: 0.55, alpha: 1)
    }

    let toggle = UISwitch().then {
        $0.onTintColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
    }

        // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        setupLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

        // MARK: - Layout
    private func setupLayout() {
        let timeRow = UIStackView(arrangedSubviews: [timeLabel, ampmLabel]).then {
            $0.axis      = .horizontal
            $0.alignment = .lastBaseline
            $0.spacing   = 5
        }
        let vStack = UIStackView(arrangedSubviews: [timeRow, subLabel]).then {
            $0.axis    = .vertical
            $0.spacing = 2
        }
        let hStack = UIStackView(arrangedSubviews: [vStack, toggle]).then {
            $0.axis      = .horizontal
            $0.alignment = .center
            $0.spacing   = 12
        }
        contentView.addSubview(hStack)
        hStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.top.equalToSuperview().offset(10)
            $0.bottom.equalToSuperview().inset(10)
        }
    }

        // MARK: - Configure
    func configure(with alarm: AlarmModel) {
        let enabled    = alarm.isEnabled
        timeLabel.text = alarm.timeString
        ampmLabel.text = alarm.ampmString
        subLabel.text  = alarm.repeatLabel
        toggle.isOn    = enabled

        let alpha: CGFloat = enabled ? 1.0 : 0.4
        timeLabel.alpha = alpha
        ampmLabel.alpha = alpha
        subLabel.alpha  = enabled ? 0.7 : 0.3
    }
}
