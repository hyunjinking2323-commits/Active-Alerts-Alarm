////
////  LabelCell.swift
////  Check It NOW!
////
////  Created by t2025-m0239 on 2026.03.25.
////
//
//    // MARK: - [LabelCell: 알람 이름을 입력하는 셀]
//final class LabelCell: BaseTableViewCell {
//
//    static let identifier = "LabelCell"
//    private var disposeBag = DisposeBag()
//    private var onChange: ((String) -> Void)?
//
//    private let titleLabel = UILabel().then {
//        $0.text = "레이블"
//        $0.textColor = .white
//        $0.font = .systemFont(ofSize: 17)
//    }
//
//    private let textField = UITextField().then {
//        $0.textAlignment = .right
//        $0.textColor = .lightGray
//        $0.font = .systemFont(ofSize: 17)
//        $0.placeholder = "알람"
//        $0.keyboardAppearance = .dark
//        $0.returnKeyType = .done
//    }
//
//        // BaseTableViewCell의 규칙에 따라 작성
//    override func setupHierarchy() {
//        [titleLabel, textField].forEach { contentView.addSubview($0) }
//    }
//
//    override func setupLayout() {
//        titleLabel.snp.makeConstraints {
//            $0.leading.equalToSuperview().offset(16)
//            $0.centerY.equalToSuperview()
//        }
//
//        textField.snp.makeConstraints {
//            $0.trailing.equalToSuperview().inset(16)
//            $0.centerY.equalToSuperview()
//            $0.leading.equalTo(titleLabel.snp.trailing).offset(10)
//        }
//    }
//
//    override func configureUI() {
//        backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
//        selectionStyle = .none
//
//            // 키보드 완료 시 닫기
//        textField.rx.controlEvent(.editingDidEndOnExit)
//            .subscribe(onNext: { [weak self] in self?.textField.resignFirstResponder() })
//            .disposed(by: disposeBag)
//    }
//
//    func configure(text: String, onChange: @escaping (String) -> Void) {
//        textField.text = text
//        self.onChange = onChange
//
//        textField.rx.text.orEmpty
//            .distinctUntilChanged()
//            .subscribe(onNext: { [weak self] in self?.onChange?($0) })
//            .disposed(by: disposeBag)
//    }
//
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        disposeBag = DisposeBag()
//    }
//}
