//
//  StopWatchViewModel.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.23.
//


import Foundation
import RxSwift
import RxCocoa
import RxRelay

final class StopWatchViewModel: ViewModelType {

    struct Input {
        let startButtonTap: ControlEvent<Void>
        let lapButtonTap:   ControlEvent<Void>
    }

    struct Output {
        let timeText:       Driver<String>
        let isRunning:      Driver<Bool>
        let hasElapsed:     Driver<Bool>
        let laps:           Driver<[String]>
        let fastestIdx:     Driver<Int?>
        let slowestIdx:     Driver<Int?>
        let currentLapText: Driver<String>
    }

    private let disposeBag = DisposeBag()

        // MARK: - Private State
    private let isRunningRelay      = BehaviorRelay<Bool>(value: false)
    private let hasElapsedRelay     = BehaviorRelay<Bool>(value: false)
    private let timeTextRelay       = BehaviorRelay<String>(value: "00:00.00")
    private let currentLapTextRelay = BehaviorRelay<String>(value: "00:00.00")
    private let lapsRelay           = BehaviorRelay<[TimeInterval]>(value: [])

        /// 타이머가 시작된 시각
    private var startDate:     Date?
        /// 일시정지까지 쌓인 누적 경과 시간
    private var elapsedBefore: TimeInterval = 0
        /// 현재 랩이 시작된 시점의 누적 경과 시간
    private var lapStart:      TimeInterval = 0

    private var timerDisposable: Disposable?

        // MARK: - Transform
    func transform(input: Input) -> Output {

            // 시작 / 중단
        input.startButtonTap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let running = !self.isRunningRelay.value
                self.isRunningRelay.accept(running)
                if running {
                    self.startTimer()
                } else {
                    self.pauseTimer()
                }
            })
            .disposed(by: disposeBag)

            // 랩 / 초기화
        input.lapButtonTap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if self.isRunningRelay.value {
                    self.recordLap()
                } else {
                    self.reset()
                }
            })
            .disposed(by: disposeBag)

        let lapsStringDriver = lapsRelay
            .map { [weak self] laps -> [String] in
                guard let self else { return [] }
                return laps.map { self.format($0) }
            }
            .asDriver(onErrorJustReturn: [])

        let fastestIdx = lapsRelay
            .map { laps -> Int? in
                guard laps.count >= 2 else { return nil }
                return laps.indices.min(by: { laps[$0] < laps[$1] })
            }
            .asDriver(onErrorJustReturn: nil)

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

        // MARK: - Timer Control
    private func startTimer() {
        startDate = Date()
        hasElapsedRelay.accept(true)
        timerDisposable = Observable<Int>
            .interval(.milliseconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self, let start = self.startDate else { return }
                let total = self.elapsedBefore + Date().timeIntervalSince(start)
                self.timeTextRelay.accept(self.format(total))
                self.currentLapTextRelay.accept(self.format(total - self.lapStart))
            })
    }

    private func pauseTimer() {
        if let start = startDate {
            elapsedBefore += Date().timeIntervalSince(start)
        }
        startDate = nil
        timerDisposable?.dispose()
        timerDisposable = nil
    }

    private func recordLap() {
        guard let start = startDate else { return }
        let total   = elapsedBefore + Date().timeIntervalSince(start)
        let lapTime = total - lapStart
        lapStart    = total

        var current = lapsRelay.value
        current.append(lapTime)
        lapsRelay.accept(current)
    }

    private func reset() {
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

        // MARK: - Formatter
    private func format(_ interval: TimeInterval) -> String {
        let total   = Int(interval * 100)
        let centis  = total % 100
        let seconds = (total / 100) % 60
        let minutes = (total / 6000) % 60
        return String(format: "%02d:%02d.%02d", minutes, seconds, centis)
    }
}
