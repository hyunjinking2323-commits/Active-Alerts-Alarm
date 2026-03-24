//
//  AlarmCell.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.23.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

final class AlarmCell: BaseTableViewCell {

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 10
    }

    private let meridiemLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .medium)
    }
    private let timeLabel = UILabel ().then {
        $0.font = .systemFont(ofSize: 30, weight: .semibold)
        $0.textColor = .white
    }

    private let descriptionLabel = UILabel().then {
        $0.title = "(알람 / 주중 / 월 / 화 / 수 / 목 / 금 / 토 / 일 / 주말)"

    }


}
