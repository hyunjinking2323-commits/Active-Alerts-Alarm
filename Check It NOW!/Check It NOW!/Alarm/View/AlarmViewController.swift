    //
    //  AlarmViewController.swift
    //  Check It NOW!
    //

import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class AlarmViewController: UIViewController {

        // MARK: - Properties

    private let disposeBag       = DisposeBag()
    private let viewModel        = AlarmViewModel()

    private let addAlarmRelay    = PublishRelay<AlarmModel>()
    private let updateAlarmRelay = PublishRelay<AlarmModel>()
    private let deleteAlarmRelay = PublishRelay<Int>()

        // MARK: - UI Components
    
        /// 다음 알람 시각을 표시하는 배너
    private let bannerView = UIView().then {
        $0.backgroundColor    = UIColor(white: 0.15, alpha: 1)
        $0.layer.cornerRadius = 10
        $0.isHidden           = true
    }

    private let bannerLabel = UILabel().then {
        $0.font          = .systemFont(ofSize: 13)
        $0.textColor     = UIColor(white: 0.85, alpha: 1)
        $0.textAlignment = .center
    }

        /// 알람 목록 테이블뷰
    private let tableView = UITableView(frame: .zero, style: .plain).then {
        $0.backgroundColor  = .clear
        $0.separatorColor   = UIColor(white: 0.25, alpha: 1)
        $0.register(AlarmCell.self, forCellReuseIdentifier: AlarmCell.identifier)
        $0.rowHeight = 80
    }

        /// 우측 상단 추가(+) 버튼 — Rx로 탭 처리
    private let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)

        // MARK: - Lifecycle

    init() { super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupHierarchy()
        setupLayout()
        configureUI()
        bind()
    }

        // MARK: - Setup Hierarchy

    private func setupHierarchy() {
        [bannerView, tableView].forEach { view.addSubview($0) }
        bannerView.addSubview(bannerLabel)
    }

        // MARK: - Setup Layout

    private func setupLayout() {
        bannerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.height.equalTo(32)
        }
        bannerLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        tableView.snp.makeConstraints {
            $0.top.equalTo(bannerView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

        // MARK: - Configure UI

    private func configureUI() {
            // 커스텀 타이틀 뷰 (큰 글씨)
        let titleLabel = UILabel().then {
            $0.text          = "알람"
            $0.font          = .systemFont(ofSize: 28, weight: .semibold)
            $0.textColor     = .white
            $0.textAlignment = .center
        }
        navigationItem.titleView         = titleLabel
        navigationItem.leftBarButtonItem  = editButtonItem
        navigationItem.rightBarButtonItem = addButton
        editButtonItem.title = "편집"
    }

        // MARK: - Bind

    private func bind() {
        let input = AlarmViewModel.Input(
            viewDidLoad: Observable.just(()),
            addAlarm:    addAlarmRelay,
            updateAlarm: updateAlarmRelay,
            deleteAlarm: deleteAlarmRelay
        )
        let output = viewModel.transform(input: input)

            // 1. 알람 목록 → 테이블뷰 바인딩
        output.alarmList
            .drive(tableView.rx.items(
                cellIdentifier: AlarmCell.identifier,
                cellType: AlarmCell.self
            )) { [weak self] _, model, cell in
                guard let self else { return }
                cell.configure(with: model)
                    // 토글 변경 → updateAlarm 릴레이로 전달
                cell.toggle.rx.isOn.skip(1)
                    .map { isOn -> AlarmModel in
                        var m = model
                        m.isEnabled = isOn
                        return m
                    }
                    .bind(to: self.updateAlarmRelay)
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: disposeBag)

            // 2. 다음 알람 배너 업데이트
        output.nextFireText
            .drive(onNext: { [weak self] text in
                self?.bannerLabel.text   = text
                self?.bannerView.isHidden = (text == nil)
            })
            .disposed(by: disposeBag)

            // 3. 알람 발생 → 알럿 표시
        output.alarmFired
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] alarm in
                self?.presentAlarmAlert(alarm)
            })
            .disposed(by: disposeBag)

            // 4. 스와이프 삭제
        tableView.rx.itemDeleted
            .map { $0.row }
            .bind(to: deleteAlarmRelay)
            .disposed(by: disposeBag)

            // 5. 편집 모드 토글
        editButtonItem.rx.tap
            .map { [weak self] in !(self?.tableView.isEditing ?? false) }
            .subscribe(onNext: { [weak self] isEditing in
                self?.tableView.setEditing(isEditing, animated: true)
                self?.editButtonItem.title = isEditing ? "완료" : "편집"
            })
            .disposed(by: disposeBag)

            // 6. 셀 선택 → 편집 화면
        tableView.rx.modelSelected(AlarmModel.self)
            .subscribe(onNext: { [weak self] alarm in
                self?.showEditSheet(alarm)
            })
            .disposed(by: disposeBag)

            // 7. 추가 버튼 → 추가 화면
        addButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showAddSheet()
            })
            .disposed(by: disposeBag)
    }
}

    // MARK: - Private Actions

private extension AlarmViewController {

    func showAddSheet() {
        let vc = AddAlarmViewController()
        vc.onSave = { [weak self] in self?.addAlarmRelay.accept($0) }
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    func showEditSheet(_ alarm: AlarmModel) {
        let vc = AddAlarmViewController(alarm: alarm)
        vc.onSave = { [weak self] in self?.updateAlarmRelay.accept($0) }
        vc.onDelete = { [weak self] in
            guard let self else { return }
            if let idx = viewModel.currentAlarms.firstIndex(where: { $0.id == alarm.id }) {
                deleteAlarmRelay.accept(idx)
            }
        }
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    func presentAlarmAlert(_ alarm: AlarmModel) {
        let alert = UIAlertController(title: "알람", message: alarm.label, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "중단", style: .destructive) { [weak self] _ in
            self?.viewModel.stopSound()
        })
        present(alert, animated: true)
    }
}
