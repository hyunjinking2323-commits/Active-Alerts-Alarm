    //
    //  AlarmViewModel.swift
    //  Check It NOW!
    //

import Foundation
import RxSwift
import RxCocoa
import UserNotifications
import AVFoundation

    // MARK: - AlarmViewModel

final class AlarmViewModel {

        // MARK: - Input / Output

    struct Input {
        let viewDidLoad: Observable<Void>
        let addAlarm:    PublishRelay<AlarmModel>
        let updateAlarm: PublishRelay<AlarmModel>
        let deleteAlarm: PublishRelay<Int>
    }

    struct Output {
        let alarmList:    Driver<[AlarmModel]> // 알람 목록
        let nextFireText: Driver<String?>      // 다음 알람 시각 텍스트 (없으면 nil)
        let alarmFired:   Observable<AlarmModel>
    }

        // MARK: - Properties

    private let disposeBag = DisposeBag()

    private let alarmsRelay     = BehaviorRelay<[AlarmModel]>(value: [])
    private let alarmFiredRelay = PublishRelay<AlarmModel>()
    private let persistenceKey  = "saved_alarms"
    private var audioPlayer: AVAudioPlayer?

        /// DateFormatter 재사용 (매번 생성 비용 절약)
    private let nextFireFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "a h:mm"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    var currentAlarms: [AlarmModel] { alarmsRelay.value }

        // MARK: - Init

    init() { loadAlarms() }

    deinit { print("\(Self.self) deinit") }

        // MARK: - Transform

    func transform(input: Input) -> Output {
        bindInputs(input)
        return makeOutputs()
    }
}

    // MARK: - Input Binding

private extension AlarmViewModel {

    func bindInputs(_ input: Input) {
        bindAdd(input.addAlarm)
        bindUpdate(input.updateAlarm)
        bindDelete(input.deleteAlarm)
    }

        /// 알람 추가 — 목록에 삽입 후 시간순 정렬 및 알림 예약
    func bindAdd(_ relay: PublishRelay<AlarmModel>) {
        relay
            .subscribe(onNext: { [weak self] alarm in
                guard let self else { return }
                var alarms = alarmsRelay.value
                alarms.append(alarm)
                alarms.sort { $0.time < $1.time }
                alarmsRelay.accept(alarms)
                persistAlarms(alarms)
                scheduleNotification(for: alarm)
            })
            .disposed(by: disposeBag)
    }

        /// 알람 수정 — 기존 항목 교체 후 알림 재예약
    func bindUpdate(_ relay: PublishRelay<AlarmModel>) {
        relay
            .subscribe(onNext: { [weak self] edited in
                guard let self else { return }
                var alarms = alarmsRelay.value
                guard let idx = alarms.firstIndex(where: { $0.id == edited.id }) else { return }
                cancelNotification(for: alarms[idx])
                alarms[idx] = edited
                alarms.sort { $0.time < $1.time }
                alarmsRelay.accept(alarms)
                persistAlarms(alarms)
                if edited.isEnabled { scheduleNotification(for: edited) }
            })
            .disposed(by: disposeBag)
    }

        /// 알람 삭제 — 인덱스 기준 제거 및 알림 취소
    func bindDelete(_ relay: PublishRelay<Int>) {
        relay
            .subscribe(onNext: { [weak self] index in
                guard let self else { return }
                var alarms = alarmsRelay.value
                guard index < alarms.count else { return }
                let removed = alarms.remove(at: index)
                alarmsRelay.accept(alarms)
                persistAlarms(alarms)
                cancelNotification(for: removed)
            })
            .disposed(by: disposeBag)
    }
}

    // MARK: - Output Creation

private extension AlarmViewModel {

    func makeOutputs() -> Output {
            // 활성화된 알람 중 가장 이른 시간을 "다음 알람" 텍스트로 변환
        let nextFireText = alarmsRelay
            .map { [nextFireFormatter] alarms -> String? in
                guard let next = alarms.filter({ $0.isEnabled }).min(by: { $0.time < $1.time }) else {
                    return nil
                }
                return "다음 알람: \(nextFireFormatter.string(from: next.time))"
            }
            .asDriver(onErrorJustReturn: nil)

        return Output(
            alarmList:    alarmsRelay.asDriver(),
            nextFireText: nextFireText,
            alarmFired:   alarmFiredRelay.asObservable()
        )
    }
}

    // MARK: - Sound

extension AlarmViewModel {
    func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

    // MARK: - Notification Scheduling

private extension AlarmViewModel {

        /// 알람 + 스누즈(최대 5회) 알림 예약
    func scheduleNotification(for alarm: AlarmModel) {
        let center = UNUserNotificationCenter.current()
        cancelNotification(for: alarm)
        guard alarm.isEnabled else { return }

        scheduleMainNotification(alarm, center: center)

        if alarm.isSnoozeEnabled {
            for i in 1...5 {
                scheduleSnoozeNotification(
                    alarm,
                    delayMinutes: alarm.snoozeInterval * i,
                    snoozeIndex: i,
                    center: center
                )
            }
        }
    }

    func scheduleMainNotification(_ alarm: AlarmModel, center: UNUserNotificationCenter) {
        let content = makeContent(alarm: alarm, isSnooze: false)
        let trigger = makeTrigger(from: alarm.time, repeatDays: alarm.repeatDays, offsetMinutes: 0)
        center.add(UNNotificationRequest(
            identifier: notificationID(alarm: alarm, snoozeIndex: 0),
            content: content,
            trigger: trigger
        ))
    }

    func scheduleSnoozeNotification(
        _ alarm: AlarmModel,
        delayMinutes: Int,
        snoozeIndex: Int,
        center: UNUserNotificationCenter
    ) {
        let content = makeContent(alarm: alarm, isSnooze: true)
        let trigger = makeTrigger(from: alarm.time, repeatDays: alarm.repeatDays, offsetMinutes: delayMinutes)
        center.add(UNNotificationRequest(
            identifier: notificationID(alarm: alarm, snoozeIndex: snoozeIndex),
            content: content,
            trigger: trigger
        ))
    }

    func makeContent(alarm: AlarmModel, isSnooze: Bool) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "알람" : alarm.label
        content.body  = isSnooze ? "스누즈 알람 (\(alarm.snoozeInterval)분 후)" : "알람이 울립니다!"
        content.sound = .default
        content.interruptionLevel = .timeSensitive  // iOS 15+ 방해 금지 모드 무시
        return content
    }

        /// UNCalendarNotificationTrigger 생성 (offsetMinutes 만큼 시간 오프셋 적용)
    func makeTrigger(
        from date: Date,
        repeatDays: [Int],
        offsetMinutes: Int
    ) -> UNCalendarNotificationTrigger {
        var c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let total  = (c.minute ?? 0) + offsetMinutes
        c.hour     = ((c.hour ?? 0) + total / 60) % 24
        c.minute   = total % 60
        return UNCalendarNotificationTrigger(dateMatching: c, repeats: !repeatDays.isEmpty)
    }

        /// 해당 알람의 모든 알림(메인 + 스누즈 5개) 취소
    func cancelNotification(for alarm: AlarmModel) {
        let ids = (0...5).map { notificationID(alarm: alarm, snoozeIndex: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func notificationID(alarm: AlarmModel, snoozeIndex: Int) -> String {
        "alarm_\(alarm.id.uuidString)_snooze_\(snoozeIndex)"
    }
}

    // MARK: - Persistence

private extension AlarmViewModel {

    func persistAlarms(_ alarms: [AlarmModel]) {
        guard let data = try? JSONEncoder().encode(alarms) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    func loadAlarms() {
        guard
            let data = UserDefaults.standard.data(forKey: persistenceKey),
            let list = try? JSONDecoder().decode([AlarmModel].self, from: data)
        else { return }
        alarmsRelay.accept(list)
    }
}
