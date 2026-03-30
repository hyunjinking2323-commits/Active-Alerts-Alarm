    //
    //  LabelCell.swift
    //  Check It NOW!
    //

import UIKit
import SnapKit
import Then
import RxSwift

    /// 알람 레이블 입력 전용 셀
final class LabelCell: UITableViewCell {

        // MARK: - Reuse

    static let identifier = String(describing: LabelCell.self)

        /// 재사용 시 Rx 바인딩 중첩 방지
    var disposeBag = DisposeBag()
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

        // MARK: - UI

    private let titleLabel = UILabel().then {
        $0.text      = "레이블"
        $0.font      = .systemFont(ofSize: 17)
        $0.textColor = .white
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

        /// 외부에서 텍스트 바인딩 가능하도록 internal 접근 허용
    let textField = UITextField().then {
        $0.font              = .systemFont(ofSize: 17)
        $0.textColor         = .white
        $0.textAlignment     = .right
        $0.clearButtonMode   = .whileEditing
        $0.returnKeyType     = .done
        $0.attributedPlaceholder = NSAttributedString(
            string: "없음",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
    }

        // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle              = .none
        backgroundColor             = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        contentView.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
        setupHierarchy()
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupHierarchy() {
        [titleLabel, textField].forEach { contentView.addSubview($0) }
    }

    private func setupLayout() {
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        textField.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
    }
}
