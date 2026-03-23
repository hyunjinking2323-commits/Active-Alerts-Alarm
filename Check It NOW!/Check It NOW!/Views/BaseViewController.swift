    //
    //  BaseViewController.swift
    //  Check It NOW!
    //
    //  Created by t2025-m0239 on 2026.03.23.
    //

import UIKit
import RxSwift
import SnapKit
import Then

class BaseViewController: UIViewController {

    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureUI()
        setupConstraints()
        bind()
    }
    // 1. UI 속성 설정 (Then 라이브러리 활용하는 곳)
    func configureUI() {
        // 자식 클래스에서 override해서 사용
    }
    // 2. 레이아웃 설정 (SnapKit 활용하는 곳)
    func setupConstraints() {
        // 자식 클래스에서 override해서 사용
    }
    // 3. RxSwift 바인딩 (ViewModel과 연결하는 곳)
    func bind() {
        // 자식 클래스에서 override해서 사용
    }
}

