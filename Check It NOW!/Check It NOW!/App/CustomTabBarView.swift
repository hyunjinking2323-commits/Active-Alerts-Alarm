    //
    //  CustomTabBarView.swift
    //  Check It NOW!
    //

import UIKit
import Then

final class CustomTabBarView: UIView {

        // MARK: - Types

    struct Item {
        let title: String
        let icon:  String
    }

        // MARK: - Properties

    var onTabSelected: ((Int) -> Void)?

    private var buttons:      [UIButton] = []
    private var selectedIndex = 0

        // MARK: - Style

    private let selectedColor  = UIColor.systemOrange
    private let normalColor    = UIColor(white: 1.0, alpha: 1)  // 비선택: 밝은 회색
    private let barColor       = UIColor(white: 0.18, alpha: 1)
    private let highlightColor = UIColor(white: 0.32, alpha: 1)  // 선택 캡슐 배경

        // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor    = barColor
        layer.cornerRadius = 40
        clipsToBounds      = true
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Configure

    func configure(items: [Item]) {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = items.enumerated().map { makeTabButton(item: $1, index: $0) }

        let stack = UIStackView(arrangedSubviews: buttons).then {
            $0.axis         = .horizontal
            $0.distribution = .fillEqually
            $0.alignment    = .center
            $0.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            $0.isLayoutMarginsRelativeArrangement = true
        }

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

        // MARK: - Selection

    func setSelected(index: Int) {
        selectedIndex = index
        buttons.enumerated().forEach { i, btn in
            let isSelected = (i == index)

                // 아이콘 + 텍스트 항상 표시, 색상으로만 선택 구분
            if let vStack = btn.subviews.compactMap({ $0 as? UIStackView }).first {
                let imageView = vStack.arrangedSubviews.first as? UIImageView
                let label     = vStack.arrangedSubviews.last  as? UILabel
                let color     = isSelected ? selectedColor : normalColor
                imageView?.tintColor = color
                label?.textColor     = color
            }

                // 선택된 탭에 캡슐 배경 애니메이션
            UIView.animate(withDuration: 0.3, delay: 0,
                           usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3) {
                btn.backgroundColor    = isSelected ? self.highlightColor : .clear
                btn.layer.cornerRadius = isSelected ? 24 : 0
            }
        }
    }

        // MARK: - Private

    private func makeTabButton(item: Item, index: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.tag             = index
        btn.backgroundColor = .clear

        let imageView = UIImageView().then {
            $0.image       = UIImage(systemName: item.icon,
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
            $0.tintColor   = normalColor
            $0.contentMode = .scaleAspectFit
            $0.isUserInteractionEnabled = false
        }

        let label = UILabel().then {
            $0.text          = item.title
            $0.font          = .systemFont(ofSize: 11, weight: .medium)
            $0.textColor     = normalColor
            $0.textAlignment = .center
            $0.isUserInteractionEnabled = false
        }

            // 아이콘 + 텍스트 세로 배치, 항상 표시
        let vStack = UIStackView(arrangedSubviews: [imageView, label]).then {
            $0.axis      = .vertical
            $0.alignment = .center
            $0.spacing   = 3
            $0.isUserInteractionEnabled = false
        }

        btn.addSubview(vStack)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vStack.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            vStack.centerYAnchor.constraint(equalTo: btn.centerYAnchor)
        ])

        btn.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func tabButtonTapped(_ sender: UIButton) {
        onTabSelected?(sender.tag)
    }
}
