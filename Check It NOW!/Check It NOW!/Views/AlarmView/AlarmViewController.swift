//
//  AlarmViewController.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.23.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

class AlarmViewController: BaseViewController {

    let addVC = AddAlarmViewController()
    let navController = UINavigationController(rootViewController: addVC)
    self.present(navController, animated: true)

    private let alarmTableView = UITableView().then {
        $0.backgroundColor = .clear
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    private let addButton = UIButton().then {
        $0.setTitle("+", for: .normal)
        $0.setTitleColor(.orange, for: .normal)
    }

    override func configureUI() {
        [alarmTableView, addButton].forEach { view.addSubview($0) }
    }

    override func setupConstraints() {
        addButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(5)
            $0.trailing.equalToSuperview().inset(10)
        }

        alarmTableView.snp.makeConstraints {
            $0.top.equalTo(addButton.snp.bottom).offset(10)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func bind() {
        addButton.rx.tap
            .subscribe(onNext: { [weak self] in
                print("알람 추가화면으로 이동")
            })
            .disposed(by: disposeBag)
    }


}

