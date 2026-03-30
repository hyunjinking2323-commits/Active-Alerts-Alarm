    //
    //  StopWatchViewModel.swift
    //  Check It NOW!
    //
    //  Created by t2025-m0239 on 2026.03.23.
    //

import Foundation
import RxSwift
import RxCocoa

final class StopWatchViewModel {

        // MARK: - Input / Output

    struct Input {
        let startButtonTap: ControlEvent<Void>
        let lapButtonTap:   ControlEvent<Void>
    }

    struct Output {
        let timeText:       Driver<String>   // 전체 경과 시간
        let isRunning:      Driver<Bool>     // 실행 여부
        let hasElapsed:     Driver<Bool>     // 1번이라도 시작했는지
        let laps:           Driver<[String]> // 기록된 랩 목록
        let fastestIdx:     Driver<Int?>     // 가장 빠른 랩 인덱스
        let slowestIdx:     Driver<Int?>     // 가장 느린 랩 인덱스
        let currentLapText: Driver<String>   // 현재 랩 진행 시간
    }

        // MARK: - Properties

    private let disposeBag = DisposeBag()

    private let isRunningRelay      = BehaviorRelay<Bool>(value: false)
    private let hasElapsedRelay     = BehaviorRelay<Bool>(value: false)
    private let timeTextRelay       = BehaviorRelay<String>(value: "00:00.00")
    private let currentLapTextRelay = BehaviorRelay<String>(value: "00:00.00")
    private let lapsRelay           = BehaviorRelay<[TimeInterval]>(value: [])

    private var startDate:     Date?
    private var elapsedBefore: TimeInterval = 0  // 일시정지까지 쌓인 누적 경과 시간
    private var lapStart:      TimeInterval = 0  // 현재 랩 시작 시점의 누적 경과 시간

    private var timerDisposable: Disposable?

    deinit { print("\(Self.self) deinit") }

        // MARK: - Transform

    func transform(input: Input) -> Output {
            // 시작 / 중단 토글
        input.startButtonTap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let running = !isRunningRelay.value
                isRunningRelay.accept(running)
                running ? startTimer() : pauseTimer()
            })
            .disposed(by: disposeBag)

            // 랩 기록 / 초기화
        input.lapButtonTap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                isRunningRelay.value ? recordLap() : reset()
            })
            .disposed(by: disposeBag)

            // 랩 목록 → 문자열 배열 변환
        let lapsStringDriver = lapsRelay
            .map { [weak self] laps -> [String] in laps.map { self?.format($0) ?? "" } }
            .asDriver(onErrorJustReturn: [])

            // 가장 빠른 랩 인덱스 (2개 이상일 때만 유효)
        let fastestIdx = lapsRelay
            .map { laps -> Int? in
                guard laps.count >= 2 else { return nil }
                return laps.indices.min(by: { laps[$0] < laps[$1] })
            }
            .asDriver(onErrorJustReturn: nil)

            // 가장 느린 랩 인덱스 (2개 이상일 때만 유효)
        let slowestIdx = lapsRelay
            .map { laps -> Int? in
                guard laps.count >= 2 else { return nil }
                return laps.indices.max(by: { laps[$0] < laps[$1] })
            }
            .asDriver(onErrorJustReturn: nil)

        return Output(
            timeText:       timeTextRelay.asDriver(),
            isRunning:      isRunningRelay.asDriver(),
            hasElapsed:     hasElapsedRelay.asDriver(),
            laps:           lapsStringDriver,
            fastestIdx:     fastestIdx,
            slowestIdx:     slowestIdx,
            currentLapText: currentLapTextRelay.asDriver()
        )
    }
}

    // MARK: - Timer Control

private extension StopWatchViewModel {

    func startTimer() {
        startDate = Date()
        hasElapsedRelay.accept(true)
            // 10ms 간격으로 UI 갱신
        timerDisposable = Observable<Int>
            .interval(.milliseconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self, let start = startDate else { return }
                let total = elapsedBefore + Date().timeIntervalSince(start)
                timeTextRelay.accept(format(total))
                currentLapTextRelay.accept(format(total - lapStart))
            })
    }

    func pauseTimer() {
        if let start = startDate {
            elapsedBefore += Date().timeIntervalSince(start)
        }
        startDate = nil
        timerDisposable?.dispose()
        timerDisposable = nil
    }

    func recordLap() {
        guard let start = startDate else { return }
        let total   = elapsedBefore + Date().timeIntervalSince(start)
        let lapTime = total - lapStart
        lapStart    = total
        var current = lapsRelay.value
        current.append(lapTime)
        lapsRelay.accept(current)
    }

    func reset() {
        timerDisposable?.dispose()
        timerDisposable = nil
        startDate       = nil
        elapsedBefore   = 0
        lapStart        = 0
        timeTextRelay.accept("00:00.00")
        currentLapTextRelay.accept("00:00.00")
        lapsRelay.accept([])
        hasElapsedRelay.accept(false)
    }

        /// TimeInterval → "MM:SS.cc" 형식
    func format(_ interval: TimeInterval) -> String {
        let total   = Int(interval * 100)
        let centis  = total % 100
        let seconds = (total / 100) % 60
        let minutes = (total / 6000) % 60
        return String(format: "%02d:%02d.%02d", minutes, seconds, centis)
    }
}
