//
//  StopWatchViewController.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.23.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class StopWatchViewController: UIViewController {

        // MARK: - Properties

    private let disposeBag = DisposeBag()
    private let viewModel  = StopWatchViewModel()

        // MARK: - UI Components

        /// 전체 경과 시간 표시
    private let timeLabel = UILabel().then {
        $0.text          = "00:00.00"
        $0.textColor     = .white
        $0.font          = .monospacedDigitSystemFont(ofSize: 85, weight: .thin)
        $0.textAlignment = .center
    }

        /// 랩 / 재설정 버튼 (왼쪽)
    private let lapButton = UIButton().then {
        $0.setTitle("재설정", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.setTitleColor(UIColor.white.withAlphaComponent(0.35), for: .disabled)
        $0.titleLabel?.font   = .systemFont(ofSize: 18, weight: .regular)
        $0.backgroundColor    = UIColor(white: 0.2, alpha: 1)
        $0.layer.cornerRadius = 40
        $0.clipsToBounds      = true
        $0.isEnabled          = false
        $0.alpha              = 0.4
    }

        /// 시작 / 중단 버튼 (오른쪽)
    private let startButton = UIButton().then {
        $0.setTitle("시작", for: .normal)
        $0.setTitleColor(.systemGreen, for: .normal)
        $0.titleLabel?.font   = .systemFont(ofSize: 18, weight: .regular)
        $0.backgroundColor    = UIColor(red: 0.0, green: 0.22, blue: 0.05, alpha: 1)
        $0.layer.cornerRadius = 40
        $0.clipsToBounds      = true
    }

    private let separatorView = UIView().then {
        $0.backgroundColor = UIColor(white: 0.25, alpha: 1)
    }

        /// 랩 기록 목록
    private let lapTableView = UITableView().then {
        $0.backgroundColor = .black
        $0.register(LapCell.self, forCellReuseIdentifier: LapCell.identifier)
        $0.separatorColor  = UIColor(white: 0.2, alpha: 1)
        $0.separatorInset  = .zero
        $0.rowHeight       = 44
        $0.tableFooterView = UIView()
    }

        // MARK: - Lifecycle

    init() { super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupHierarchy()
        setupLayout()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
            // 스톱워치 화면은 네비게이션바 숨김
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupHierarchy() {
        [timeLabel, lapButton, startButton, separatorView, lapTableView].forEach { view.addSubview($0) }
    }

    private func setupLayout() {
        timeLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(90)
            $0.leading.trailing.equalToSuperview()
        }

        startButton.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(60)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.height.equalTo(80)
        }

        lapButton.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(60)
            $0.leading.equalToSuperview().inset(20)
            $0.width.height.equalTo(80)
        }

        separatorView.snp.makeConstraints {
            $0.top.equalTo(startButton.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        lapTableView.snp.makeConstraints {
            $0.top.equalTo(separatorView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

        // MARK: - Bind

    private func bind() {
        let input = StopWatchViewModel.Input(
            startButtonTap: startButton.rx.tap,
            lapButtonTap:   lapButton.rx.tap
        )

        let output = viewModel.transform(input: input)

            // 1. 전체 경과 시간 표시
        output.timeText
            .drive(timeLabel.rx.text)
            .disposed(by: disposeBag)

            // 2. 버튼 상태 동기화 (시작↔중단, 랩↔재설정)
        Driver.combineLatest(output.isRunning, output.hasElapsed)
            .drive(onNext: { [weak self] isRunning, hasElapsed in
                guard let self else { return }

                    // 시작/중단 버튼
                startButton.setTitle(isRunning ? "중단" : "시작", for: .normal)
                startButton.setTitleColor(isRunning ? .systemRed : .systemGreen, for: .normal)
                startButton.backgroundColor = isRunning
                ? UIColor(red: 0.22, green: 0.0, blue: 0.0, alpha: 1)
                : UIColor(red: 0.0, green: 0.22, blue: 0.05, alpha: 1)

                    // 랩/재설정 버튼
                lapButton.setTitle(isRunning ? "랩" : "재설정", for: .normal)
                let canLap = isRunning || hasElapsed
                lapButton.isEnabled = canLap
                lapButton.alpha     = canLap ? 1.0 : 0.4
            })
            .disposed(by: disposeBag)

            // 3. 랩 테이블: 현재 랩(상단) + 기록된 랩 목록
        let currentDriver = Driver.combineLatest(output.hasElapsed, output.currentLapText) {
            (hasElapsed: $0, text: $1)
        }
        let lapDataDriver = Driver.combineLatest(output.laps, output.fastestIdx, output.slowestIdx) {
            (laps: $0, fastest: $1, slowest: $2)
        }

        Driver.combineLatest(currentDriver, lapDataDriver)
            .map { current, lapData -> [(lap: String, time: String, highlight: LapCell.Highlight)] in
                var result: [(lap: String, time: String, highlight: LapCell.Highlight)] = []
                let count = lapData.laps.count

                    // 현재 진행 중인 랩 (맨 위에 추가)
                if current.hasElapsed {
                    result.append(("랩 \(count + 1)", current.text, .none))
                }

                    // 기록된 랩 (최신순으로 역순 표시)
                for (row, time) in lapData.laps.reversed().enumerated() {
                    let originalIdx = count - 1 - row
                    let h: LapCell.Highlight
                    if let fi = lapData.fastest, originalIdx == fi      { h = .fastest }
                    else if let si = lapData.slowest, originalIdx == si { h = .slowest }
                    else                                                 { h = .none    }
                    result.append(("랩 \(count - row)", time, h))
                }
                return result
            }
            .drive(lapTableView.rx.items(
                cellIdentifier: LapCell.identifier,
                cellType: LapCell.self
            )) { _, element, cell in
                cell.configure(lap: element.lap, time: element.time, highlight: element.highlight)
            }
            .disposed(by: disposeBag)
    }
}
