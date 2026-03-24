    //
    //  BaseTableViewCell.swift
    //  Check It NOW!
    //
    //  Created by t2025-m0239 on 2026.03.23.
    //

import UIKit
import RxSwift
import SnapKit
import Then

class BaseTableViewCell: UITableViewCell {

    var disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super .init(style: style, reuseIdentifier: reuseIdentifier)

        configrueUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func configureUI() {

    }

    override func setupConstraints() {

    }

    override func prepareForReuse() {
        super.init()
        disposeBag = DisposeBag()
    }
}
