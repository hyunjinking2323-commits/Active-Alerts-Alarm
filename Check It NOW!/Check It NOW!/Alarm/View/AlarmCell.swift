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

final class AlarmCell: BaseTableViewCell {

        // MARK: - [UI 컴포넌트]
    private let timeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 48, weight: .regular)
        $0.textColor = .white
    }

    private let ampmLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 24, weight: .regular)
        $0.textColor = .white
    }

    private let subLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .regular)
        $0.textColor = .white
    }

    let toggle = UISwitch().then {
        $0.onTintColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
    }

        // MARK: - [레이아웃 구성]
    override func setupHierarchy() {
            // 1. [오전/오후 + 시간] 스택 (왼쪽 정렬)
        let timeRow = UIStackView(arrangedSubviews: [ampmLabel, timeLabel]).then {
            $0.axis      = .horizontal
            $0.alignment = .lastBaseline
            $0.spacing   = 5
        }
            // 2. [시간줄 + 반복라벨] 스택 (세로 정렬)
        let vStack = UIStackView(arrangedSubviews: [timeRow, subLabel]).then {
            $0.axis    = .vertical
            $0.alignment = .leading // 왼쪽 정렬 고정
            $0.spacing = 2
        }
            // 3. 여백을 만들어주는 투명한 뷰 (Spacer)
        let spacer = UIView()
            // 4. 전체 가로 스택 [텍스트 정보 - Spacer - 토글]
        let hStack = UIStackView(arrangedSubviews: [vStack, spacer, toggle]).then {
            $0.axis      = .horizontal
            $0.alignment = .center
            $0.distribution = .fill // spacer가 남는 공간을 다 채우도록 설정
        }

        contentView.addSubview(hStack)

        hStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.top.equalToSuperview().offset(10)
            $0.bottom.equalToSuperview().inset(10)
        }
            // spacer가 가질 수 있는 모든 공간을 차지하게 함으로써 토글을 오른쪽 끝으로 밀어냅니다.
        spacer.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(10)
        }
    }
        // MARK: - [데이터 구성]
    func configure(with alarm: AlarmModel) {
        let enabled    = alarm.isEnabled
        timeLabel.text = alarm.timeString
        ampmLabel.text = alarm.ampmString
        subLabel.text  = alarm.repeatLabel
        toggle.isOn    = enabled

            // 비활성화 시 흐릿하게 보이도록 처리
        let alpha: CGFloat = enabled ? 1.0 : 0.6
        timeLabel.alpha = alpha
        ampmLabel.alpha = alpha
        subLabel.alpha  = enabled ? 1.0 : 0.6
    }
}
