//
//  BaseViewController.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.24.
//

import UIKit
import RxSwift
import SnapKit
import Then

class BaseViewController: UIViewController {
    var disposeBag = DisposeBag()

    init() {
        super.init(nibName: nil, bundle: nil)
    }


    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black // 시계 앱 기본 테마

        setupHierarchy()
        setupLayout()
        bind()
    }

        /// UI 구성요소 추가 (addSubview 등)
    func setupHierarchy() {}

        /// SnapKit 레이아웃 설정
    func setupLayout() {}

        /// RxSwift 바인딩 로직
    func bind() {}
}
