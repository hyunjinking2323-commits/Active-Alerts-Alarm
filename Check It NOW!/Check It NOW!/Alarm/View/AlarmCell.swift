    //
    //  AlarmCell.swift
    //  Check It NOW!
    //

import UIKit
import Then
import SnapKit
import RxSwift

final class AlarmCell: UITableViewCell {

        // MARK: - Reuse

        /// 타입 이름을 재사용 식별자로 자동 생성
    static let identifier = String(describing: AlarmCell.self)

        /// 셀 재사용 시 DisposeBag 교체 → Rx 바인딩 중첩 방지
    var disposeBag = DisposeBag()
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

        // MARK: - UI Components

    private let timeLabel = UILabel().then {
        $0.font      = .systemFont(ofSize: 48, weight: .regular)
        $0.textColor = .white
    }

    private let ampmLabel = UILabel().then {
        $0.font      = .systemFont(ofSize: 24, weight: .regular)
        $0.textColor = .white
    }

    private let subLabel = UILabel().then {
        $0.font      = .systemFont(ofSize: 15, weight: .regular)
        $0.textColor = .white
    }

        /// 외부(AlarmViewController)에서 Rx 바인딩 가능하도록 내부 접근 허용
    let toggle = UISwitch().then {
        $0.onTintColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
    }

        // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle  = .none
        backgroundColor = .black
        setupHierarchy()
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Setup Hierarchy & Layout

    private func setupHierarchy() {
            // 시:분 + 오전/오후 가로 스택
        let timeRow = UIStackView(arrangedSubviews: [ampmLabel, timeLabel]).then {
            $0.axis      = .horizontal
            $0.alignment = .lastBaseline
            $0.spacing   = 5
        }

            // 시간행 + 부제목 세로 스택
        let vStack = UIStackView(arrangedSubviews: [timeRow, subLabel]).then {
            $0.axis      = .vertical
            $0.alignment = .leading
            $0.spacing   = 2
        }

        let spacer = UIView()

        let hStack = UIStackView(arrangedSubviews: [vStack, spacer, toggle]).then {
            $0.axis         = .horizontal
            $0.alignment    = .center
            $0.distribution = .fill
        }

        contentView.addSubview(hStack)
        hStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.top.equalToSuperview().offset(10)
            $0.bottom.equalToSuperview().inset(10)
        }
        spacer.snp.makeConstraints { $0.width.greaterThanOrEqualTo(10) }
    }

        // MARK: - Configure

        /// 알람 데이터로 셀 UI 갱신
    func configure(with alarm: AlarmModel) {
        timeLabel.text = alarm.timeString
        ampmLabel.text = alarm.ampmString
        subLabel.text  = alarm.repeatLabel
        toggle.isOn    = alarm.isEnabled

            // 비활성 알람은 흐리게 표시
        let alpha: CGFloat = alarm.isEnabled ? 1.0 : 0.6
        [timeLabel, ampmLabel, subLabel].forEach { $0.alpha = alpha }
    }
}
