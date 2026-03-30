    //
    //  TimerListViewController.swift
    //  Check It NOW!
    //

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

    // MARK: - ActiveTimer

    /// 실행 중인 타이머 한 개를 캡슐화
    /// - output을 생성 시점에 캐싱 → cellForRowAt 재호출 시 transform 중복 실행 방지
    /// - transform 중복 실행 시 relay 구독이 쌓여 재생 버튼이 두 번 눌려야 작동하는 문제 발생
private final class ActiveTimer {
    let model:           TimerModel
    let viewModel:       TimerViewModel
    let startPauseRelay = PublishRelay<Void>()
    let cancelRelay     = PublishRelay<Void>()

        /// transform 결과 캐싱 — 단 한 번만 호출
    let output: TimerViewModel.Output

    init(model: TimerModel, viewModel: TimerViewModel) {
        self.model     = model
        self.viewModel = viewModel

        let input = TimerViewModel.Input(
            startPause:      startPauseRelay,
            cancel:          cancelRelay,
            selectedSeconds: PublishRelay<Double>(),
            labelText:       PublishRelay<String>(),
            openSoundPicker: PublishRelay<Void>(),
            selectedSoundID: PublishRelay<Int>(),
            deleteTimer:     PublishRelay<UUID>()
        )
        self.output = viewModel.transform(input: input)
    }
}

    // MARK: - TimerListViewController

final class TimerListViewController: UIViewController {

        // MARK: - Properties

    private let disposeBag = DisposeBag()

        /// 최근 항목 저장/불러오기 전용 ViewModel
    private let viewModel: TimerViewModel

    private let deleteTimerRelay = PublishRelay<UUID>()

    private var activeTimers: [ActiveTimer] = []
    private var recentTimers: [TimerModel]  = []

        // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.backgroundColor     = .black
        $0.separatorColor      = UIColor.white.withAlphaComponent(0.1)
        $0.separatorInset      = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        $0.rowHeight           = UITableView.automaticDimension
        $0.estimatedRowHeight  = 90
        $0.sectionHeaderHeight = 44
        $0.register(TimerCell.self, forCellReuseIdentifier: TimerCell.identifier)
    }

    private let addButton = UIBarButtonItem(
        image: UIImage(systemName: "plus"),
        style: .plain,
        target: nil,
        action: nil
    ).then { $0.tintColor = .systemOrange }

    private let editButton = UIBarButtonItem(
        title: "편집",
        style: .plain,
        target: nil,
        action: nil
    ).then { $0.tintColor = .systemOrange }

        // MARK: - Init

    init(viewModel: TimerViewModel = TimerViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) { fatalError() }

        // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupHierarchy()
        setupLayout()
        configureUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyNavigationBarStyle()
    }

        // MARK: - Setup

    private func setupHierarchy() {
        view.addSubview(tableView)
    }

    private func setupLayout() {
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func configureUI() {
        tableView.delegate   = self
        tableView.dataSource = self
        setupNavigationBar()
    }

        // MARK: - Bind

    private func bind() {
        let input = TimerViewModel.Input(
            startPause:      PublishRelay<Void>(),
            cancel:          PublishRelay<Void>(),
            selectedSeconds: PublishRelay<Double>(),
            labelText:       PublishRelay<String>(),
            openSoundPicker: PublishRelay<Void>(),
            selectedSoundID: PublishRelay<Int>(),
            deleteTimer:     deleteTimerRelay
        )
        let output = viewModel.transform(input: input)

        bindRecentTimers(output: output)
        bindEditButton()
        bindAddButton()
        bindSelection()
    }

        // MARK: - Bind: 최근 항목 갱신

    private func bindRecentTimers(output: TimerViewModel.Output) {
        output.recentTimers
            .drive(onNext: { [weak self] timers in
                guard let self else { return }
                recentTimers = timers
                tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

        // MARK: - Bind: 편집 버튼

    private func bindEditButton() {
        editButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                let editing = !owner.tableView.isEditing
                owner.tableView.setEditing(editing, animated: true)
                owner.editButton.title = editing ? "완료" : "편집"
            })
            .disposed(by: disposeBag)
    }

        // MARK: - Bind: 추가 버튼

    private func bindAddButton() {
        addButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.presentAddEditViewController(mode: .add)
            })
            .disposed(by: disposeBag)
    }

        // MARK: - Bind: 셀 선택

    private func bindSelection() {
        tableView.rx.itemSelected
            .withUnretained(self)
            .subscribe(onNext: { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
                owner.handleSelection(at: indexPath)
            })
            .disposed(by: disposeBag)
    }
}

    // MARK: - UITableViewDataSource

extension TimerListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? activeTimers.count : filteredRecentTimers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TimerCell.identifier, for: indexPath
        ) as? TimerCell else { return UITableViewCell() }

        switch indexPath.section {
            case 0:  configureActiveCell(cell, at: indexPath)
            default: configureRecentCell(cell, at: indexPath)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 1
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard editingStyle == .delete, indexPath.section == 1 else { return }
        deleteTimerRelay.accept(filteredRecentTimers[indexPath.row].id)
    }
}

    // MARK: - Cell Configuration

private extension TimerListViewController {

        /// 실행 중인 타이머 ID를 제외한 최근 항목
    var filteredRecentTimers: [TimerModel] {
        let activeIDs = Set(activeTimers.map { $0.model.id })
        return recentTimers.filter { !activeIDs.contains($0.id) }
    }

        /// 섹션 0: 실행 중인 타이머 셀
        /// 캐싱된 output 사용 → transform 재호출 없이 구독 중복 방지
    func configureActiveCell(_ cell: TimerCell, at indexPath: IndexPath) {
        let active = activeTimers[indexPath.row]

        cell.configure(with: active.model)
        cell.bindProgress(
            timeText: active.output.timeText,
            progress: active.output.progress,
            state:    active.output.timerState
        )

            // 재생/일시정지 버튼 탭
        cell.playTapped
            .subscribe(onNext: { [weak self, weak cell] in
                active.startPauseRelay.accept(())
                if let indexPath = self?.tableView.indexPath(for: cell!) {
                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                }
            })
            .disposed(by: cell.disposeBag)

            // setting 상태 복귀 시 섹션 0에서 제거
        active.output.timerState
            .asObservable()
            .filter { $0 == .setting }
            .take(1)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.removeActiveTimer(id: active.model.id)
            })
            .disposed(by: cell.disposeBag)
    }

        /// 섹션 1: 최근 항목 셀
    func configureRecentCell(_ cell: TimerCell, at indexPath: IndexPath) {
        let model = filteredRecentTimers[indexPath.row]
        cell.configure(with: model)
        cell.setRunning(false)
        cell.setRingProgress(1.0, animated: false)

        cell.playTapped
            .take(1)
            .subscribe(onNext: { [weak self] in
                self?.startTimerInline(with: model)
            })
            .disposed(by: cell.disposeBag)
    }
}

    // MARK: - UITableViewDelegate

extension TimerListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 { return .leastNormalMagnitude }
        return filteredRecentTimers.isEmpty ? .leastNormalMagnitude : 44
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1, !filteredRecentTimers.isEmpty else { return nil }

        let header = UIView().then { $0.backgroundColor = .black }
        let label  = UILabel().then {
            $0.text      = "최근 항목"
            $0.textColor = .white
            $0.font      = .systemFont(ofSize: 20, weight: .semibold)
        }
        header.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }
        return header
    }
}

    // MARK: - Active Timer Management

private extension TimerListViewController {

    func startTimerInline(with model: TimerModel) {
        guard !activeTimers.contains(where: { $0.model.id == model.id }) else { return }

        let vm     = TimerViewModel(seconds: model.totalSeconds)
        let active = ActiveTimer(model: model, viewModel: vm)

            // performBatchUpdates는 비동기 상태 타이밍과 맞추기 어려워 reloadData 사용
        activeTimers.insert(active, at: 0)
        tableView.reloadData()

        DispatchQueue.main.async {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            self.animateSlideInFromLeft(at: IndexPath(row: 0, section: 0))
        }

        vm.startImmediately(seconds: model.totalSeconds, label: model.label)
    }

    func removeActiveTimer(id: UUID) {
        guard let idx = activeTimers.firstIndex(where: { $0.model.id == id }) else { return }
        activeTimers.remove(at: idx)
        tableView.reloadData()
    }

        /// 새 셀이 왼쪽에서 슬라이드 인되는 애니메이션
    func animateSlideInFromLeft(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let originalTransform = cell.transform
        cell.transform = CGAffineTransform(translationX: -cell.bounds.width, y: 0)
        cell.alpha = 0

        UIView.animate(
            withDuration: 0.35, delay: 0,
            usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4,
            options: .curveEaseOut
        ) {
            cell.transform = originalTransform
            cell.alpha = 1
        }
    }
}

    // MARK: - Selection Handler

private extension TimerListViewController {

    func handleSelection(at indexPath: IndexPath) {
        switch indexPath.section {
            case 0:
                let active = activeTimers[indexPath.row]
                pushTimerViewController(with: active.model, viewModel: active.viewModel)
            case 1:
                guard indexPath.row < filteredRecentTimers.count else { return }
                let model = filteredRecentTimers[indexPath.row]
                tableView.isEditing
                ? presentAddEditViewController(mode: .edit(model))
                : pushTimerViewController(with: model, viewModel: nil)
            default:
                break
        }
    }
}

    // MARK: - Navigation

private extension TimerListViewController {

    func setupNavigationBar() {
        title = "타이머"
        navigationItem.leftBarButtonItem  = editButton
        navigationItem.rightBarButtonItem = addButton
    }

    func applyNavigationBarStyle() {
        let appearance = UINavigationBarAppearance().then {
            $0.configureWithOpaqueBackground()
            $0.backgroundColor     = .black
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        navigationController?.navigationBar.then {
            $0.standardAppearance   = appearance
            $0.scrollEdgeAppearance = appearance
            $0.compactAppearance    = appearance
            $0.tintColor            = .systemOrange
        }
    }

    func presentAddEditViewController(mode: AddEditTimerMode) {
        let vc  = AddEditTimerViewController(mode: mode).then { $0.delegate = self }
        let nav = UINavigationController(rootViewController: vc).then {
            $0.modalPresentationStyle = .pageSheet
        }
        if let sheet = nav.sheetPresentationController {
            sheet.detents               = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    func pushTimerViewController(with model: TimerModel, viewModel: TimerViewModel?) {
        let vm = viewModel ?? TimerViewModel(seconds: model.totalSeconds)
        let vc = TimerViewController(viewModel: vm, seconds: model.totalSeconds, label: model.label)
        navigationController?.pushViewController(vc, animated: true)
    }
}

    // MARK: - AddEditTimerViewControllerDelegate

extension TimerListViewController: AddEditTimerViewControllerDelegate {
    func didSaveTimer(_ timer: TimerModel) {
        viewModel.saveTimer(timer)
    }
}
