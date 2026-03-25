//
//  AlarmViewModel.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.23.
//

import Foundation
import AVFoundation
import UserNotifications
import RxSwift
import RxRelay

final class AlarmViewModel: ViewModelType {

        // MARK: - I/O 정의
    struct Input {
        let viewDidLoad: Observable<Void>
        let addAlarm: PublishRelay<AlarmModel>
        let updateAlarm: PublishRelay<AlarmModel>
        let deleteAlarm: PublishRelay<Int>
    }

    struct Output {
        let alarmList: BehaviorRelay<[AlarmModel]>
        let nextFireText: BehaviorRelay<String?>
        let alarmFired: PublishRelay<AlarmModel>
    }

        // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let persistenceKey = "saved_alarms"

    private let alarmRelay = BehaviorRelay<[AlarmModel]>(value: [])
    private let nextFireRelay = BehaviorRelay<String?>(value: nil)
    private let fireRelay = PublishRelay<AlarmModel>()

    private var player: AVAudioPlayer?
    private var fireTimer: Timer?

    var currentAlarms: [AlarmModel] {
        return alarmRelay.value
    }

        // MARK: - Transform (Input -> Output)
    func transform(input: Input) -> Output {
            // 1. 초기 로드
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.load()
                self?.startFireTimer()
            })
            .disposed(by: disposeBag)

            // 2. 추가
        input.addAlarm
            .subscribe(onNext: { [weak self] newAlarm in
                var current = self?.alarmRelay.value ?? []
                current.append(newAlarm)
                self?.updateAndSave(current)
            })
            .disposed(by: disposeBag)

            // 3. 수정 및 토글
        input.updateAlarm
            .subscribe(onNext: { [weak self] updated in
                var current = self?.alarmRelay.value ?? []
                if let index = current.firstIndex(where: { $0.id == updated.id }) {
                    current[index] = updated
                    self?.updateAndSave(current)
                }
            })
            .disposed(by: disposeBag)

            // 4. 삭제
        input.deleteAlarm
            .subscribe(onNext: { [weak self] index in
                var current = self?.alarmRelay.value ?? []
                guard index < current.count else { return }
                current.remove(at: index)
                self?.updateAndSave(current)
            })
            .disposed(by: disposeBag)

        return Output(
            alarmList: alarmRelay,
            nextFireText: nextFireRelay,
            alarmFired: fireRelay
        )
    }

        // MARK: - Data Persistence (저장 및 로드)
    private func updateAndSave(_ newList: [AlarmModel]) {
        let sorted = newList.sorted { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
        alarmRelay.accept(sorted)
        save(sorted)
        updateNextFireText()
        scheduleNotifications(for: sorted)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let list = try? JSONDecoder().decode([AlarmModel].self, from: data) else { return }
        alarmRelay.accept(list)
        updateNextFireText()
    }

    private func save(_ list: [AlarmModel]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

        // MARK: - Alarm Logic (시간 계산 및 타이머)
    private func updateNextFireText() {
        let activeAlarms = alarmRelay.value.filter { $0.isEnabled }
        if activeAlarms.isEmpty {
            nextFireRelay.accept(nil)
            return
        }

        let now = Date()
        let calendar = Calendar.current
        let fireDates = activeAlarms.compactMap { alarm -> Date? in
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
            components.hour = alarm.hour
            components.minute = alarm.minute
            components.second = 0
            guard let alarmDate = calendar.date(from: components) else { return nil }
            return alarmDate <= now ? calendar.date(byAdding: .day, value: 1, to: alarmDate) : alarmDate
        }

        guard let nextDate = fireDates.min() else { return }
        let diff = calendar.dateComponents([.hour, .minute], from: now, to: nextDate)
        if let h = diff.hour, let m = diff.minute {
            nextFireRelay.accept(h > 0 ? "\(h)시간 \(m)분 후 알람" : "\(m)분 후 알람")
        }
    }

    private func startFireTimer() {
        fireTimer?.invalidate()
        fireTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkFire()
        }
    }

    private func checkFire() {
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let firing = alarmRelay.value.filter { $0.isEnabled && $0.hour == now.hour && $0.minute == now.minute }
        firing.forEach {
            fireRelay.accept($0)
            playSound($0.sound)
        }
    }

        // MARK: - Sound & Notification
    private func playSound(_ sound: AlarmSound) {
        stopSound()
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    func stopSound() {
        player?.stop()
        player = nil
    }

    private func scheduleNotifications(for list: [AlarmModel]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        list.filter { $0.isEnabled }.forEach { alarm in
            let content = UNMutableNotificationContent()
            content.title = alarm.label.isEmpty ? "알람" : alarm.label
            content.body = "\(alarm.ampmString) \(alarm.timeString)"
            content.sound = UNNotificationSound(named: UNNotificationSoundName(alarm.sound.rawValue + ".mp3"))

            var dc = DateComponents()
            dc.hour = alarm.hour
            dc.minute = alarm.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
            center.add(request)
        }
    }
}
