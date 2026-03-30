    //
    //  SoundPickerSheetView.swift
    //  Check It NOW!
    //

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

    /// 소리 선택 슬라이드업 시트 뷰
    ///
    /// - `sounds`: 표시할 사운드 목록
    /// - `currentSelectedID`: 현재 선택된 ID 설정
    /// - `selectedSoundID`: 사용자가 선택하면 Observable로 방출
final class SoundPickerSheetView: UIView {

        // MARK: - Properties

    private let disposeBag      = DisposeBag()
    private let soundsRelay     = BehaviorRelay<[SoundModel]>(value: [])
    private let selectedIDRelay = BehaviorRelay<Int>(value: 1005)
    private let selectedOutRelay = PublishRelay<Int>()

    var sounds: [SoundModel] {
        get { soundsRelay.value }
        set { soundsRelay.accept(newValue) }
    }

        /// ViewModel의 selectedSoundID output을 동기화
    var currentSelectedID: Int {
        get { selectedIDRelay.value }
        set { selectedIDRelay.accept(newValue) }
    }

        /// 외부 구독용 — 사용자가 선택한 사운드 ID
    var selectedSoundID: Observable<Int> { selectedOutRelay.asObservable() }

        // MARK: - UI

    private let containerView = UIView().then {
        $0.backgroundColor     = UIColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 1)
        $0.layer.cornerRadius  = 16
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds       = true
    }

    private let handleBar = UIView().then {
        $0.backgroundColor    = UIColor(white: 0.4, alpha: 1)
        $0.layer.cornerRadius = 2.5
    }

    private let titleLabel = UILabel().then {
        $0.text          = "소리"
        $0.textColor     = .white
        $0.font          = .systemFont(ofSize: 17, weight: .semibold)
        $0.textAlignment = .center
    }

    private let tableView = UITableView().then {
        $0.backgroundColor = .clear
        $0.separatorColor  = UIColor(white: 0.25, alpha: 1)
        $0.separatorInset  = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        $0.rowHeight       = 52
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "SoundCell")
        $0.isScrollEnabled = false
    }

        // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupLayout()
        bind()
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Setup

    private func setupHierarchy() {
        addSubview(containerView)
        [handleBar, titleLabel, tableView].forEach { containerView.addSubview($0) }
    }

    private func setupLayout() {
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }

        handleBar.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(36); $0.height.equalTo(5)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(handleBar.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(24)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func bind() {
            // sounds + selectedID 조합 → 셀 데이터로 변환
            // Driver.combineLatest 사용 이유: reloadData()와 rx.items 동시 사용 시 크래시 방지
        Driver.combineLatest(
            soundsRelay.asDriver(),
            selectedIDRelay.asDriver()
        )
        .map { sounds, selectedID in
            sounds.map { model in (model: model, isSelected: model.id == selectedID) }
        }
        .drive(tableView.rx.items(
            cellIdentifier: "SoundCell",
            cellType: UITableViewCell.self
        )) { _, item, cell in
            cell.textLabel?.text      = item.model.name
            cell.textLabel?.textColor = .white
            cell.textLabel?.font      = .systemFont(ofSize: 17)
            cell.backgroundColor      = .clear
            cell.selectionStyle       = .none
            cell.tintColor            = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
            cell.accessoryType        = item.isSelected ? .checkmark : .none
        }
        .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                let sounds = owner.soundsRelay.value
                guard indexPath.row < sounds.count else { return }
                let model = sounds[indexPath.row]
                owner.selectedIDRelay.accept(model.id)
                owner.selectedOutRelay.accept(model.id)
            }
            .disposed(by: disposeBag)
    }
}
