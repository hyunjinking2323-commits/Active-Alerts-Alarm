//
//  BaseTableViewCell.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.24.
//


import UIKit
import RxSwift
import SnapKit
import Then

class BaseTableViewCell: UITableViewCell {
        // 셀 등록 및 재사용을 위한 ID 자동 생성
    static var identifier: String {
        return String(describing: self)
    }

    var disposeBag = DisposeBag()

        // 셀이 재사용될 때 호출 (중요: Rx 바인딩 중첩 방지)
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .black // 기본 배경 투명 (시계 앱은 보통 검은색 배경)
        setupHierarchy()
        setupLayout()
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError() }

        /// UI 요소 추가
    func setupHierarchy() {}

        /// SnapKit 레이아웃
    func setupLayout() {}

        /// 기타 UI 속성 설정 (색상, 폰트 등)
    func configureUI() {}
}
