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

    /// 알람 화면의 비즈니스 로직을 담당하는 ViewModel.
    /// CRUD, 사운드 재생, 알람 발화 감지, 로컬 알림 등록을 모두 처리합니다.
final class AlarmViewModel {

        // MARK: - Output (View가 구독하는 스트림)

        /// 전체 알람 목록. 추가/수정/삭제 시 자동으로 방출됩니다.
    let alarms = BehaviorRelay<[AlarmModel]>(value: [])

        /// 가장 가까운 활성 알람까지 남은 시간 문자열.
        /// 활성 알람이 없으면 nil을 방출해 배너를 숨깁니다.
    let nextFireText = BehaviorRelay<String?>(value: nil)

        /// 알람 발화 이벤트. 포그라운드 상태에서 시각이 일치하는 알람을 방출합니다.
    let alarmFired = PublishRelay<AlarmModel>()

        // MARK: - Private Properties

        /// AVAudioPlayer로 알람 사운드를 재생합니다.
    private var player: AVAudioPlayer?

        /// 30초마다 현재 시각과 알람 시각을 비교하는 타이머입니다.
    private var fireTimer: Timer?

        /// UserDefaults 저장 키
    private let persistenceKey = "saved_alarms"

        // MARK: - Init

    init() {
        load()           // 앱 시작 시 저장된 알람 불러오기
        startFireTimer() // 포그라운드 발화 감지 타이머 시작
    }

        // MARK: - CRUD

        /// 새 알람을 목록 끝에 추가합니다.
    func add(_ alarm: AlarmModel) {
        var list = alarms.value
        list.append(alarm)
        commit(list)
    }

        /// 기존 알람을 수정합니다. id가 일치하는 항목을 교체합니다.
    func update(_ alarm: AlarmModel) {
        var list = alarms.value
        guard let index = list.firstIndex(where: { $0.id == alarm.id }) else { return }
        list[index] = alarm
        commit(list)
    }

        /// 특정 인덱스의 알람을 반환합니다. 범위를 벗어나면 nil을 반환합니다.
    func alarm(at index: Int) -> AlarmModel? {
        alarms.value.indices.contains(index) ? alarms.value[index] : nil
    }

        /// 특정 인덱스의 알람을 삭제합니다.
    func delete(at index: Int) {
        var list = alarms.value
        guard list.indices.contains(index) else { return }
        list.remove(at: index)
        commit(list)
    }

        /// 특정 알람을 삭제합니다. id가 일치하는 항목을 찾아 삭제합니다.
    func delete(_ alarm: AlarmModel) {
        guard let index = alarms.value.firstIndex(where: { $0.id == alarm.id }) else { return }
        delete(at: index)
    }

        /// 알람 활성화/비활성화를 토글합니다.
    func toggle(_ alarm: AlarmModel) {
        var updated = alarm
        updated.isEnabled = !alarm.isEnabled
        update(updated)
    }

        // MARK: - Sound

        /// 알람 발화 시 호출. 해당 알람의 사운드를 재생합니다.
    func startRinging(_ alarm: AlarmModel) {
        playSound(alarm.sound)
    }

        /// 사운드 미리듣기 및 발화 재생에 사용됩니다.
    func playSound(_ sound: AlarmSound) {
            // 번들에서 mp3 파일을 찾아 AVAudioPlayer로 무한 반복 재생합니다.
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1  // -1: 무한 반복
        player?.play()
    }

        /// 재생 중인 사운드를 중지합니다.
    func stopSound() {
        player?.stop()
        player = nil
    }

        // MARK: - Private Helpers

        /// 알람 목록 변경 시 공통으로 처리해야 하는 작업을 한 곳에서 실행합니다.
        /// relay 방출 → 저장 → 배너 갱신 → 로컬 알림 재등록 순서로 진행됩니다.
    private func commit(_ list: [AlarmModel]) {
        alarms.accept(list)
        save(list)
        refreshNextFireText(list)
        scheduleNotifications(list)
    }

        /// 활성화된 알람 중 가장 가까운 것의 남은 시간을 nextFireText에 방출합니다.
    private func refreshNextFireText(_ list: [AlarmModel]) {
        let text = list
            .compactMap { $0.nextFireDescription() }
            .first
        nextFireText.accept(text)
    }

        // MARK: - Fire Timer

        /// 앱이 포그라운드 상태일 때 알람 발화를 감지합니다.
        /// 30초 간격으로 현재 시/분과 알람 시/분을 비교합니다.
    private func startFireTimer() {
        fireTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkFire()
        }
    }

        /// 현재 시/분과 일치하는 활성 알람을 alarmFired로 방출합니다.
    private func checkFire() {
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        alarms.value
            .filter { $0.isEnabled }
            .filter { $0.hour == now.hour && $0.minute == now.minute }
            .forEach { alarmFired.accept($0) }
    }

        // MARK: - Persistence

        /// 알람 목록을 JSON으로 인코딩해 UserDefaults에 저장합니다.
    private func save(_ list: [AlarmModel]) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

        /// UserDefaults에서 알람 목록을 불러와 relay에 방출합니다.
    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: persistenceKey),
            let list = try? JSONDecoder().decode([AlarmModel].self, from: data)
        else { return }
        alarms.accept(list)
        refreshNextFireText(list)
    }

        // MARK: - Local Notifications

        /// 활성화된 알람 전체를 UNCalendarNotificationTrigger로 등록합니다.
        /// 기존 알림을 모두 제거한 뒤 새로 등록하므로 항상 최신 상태를 유지합니다.
    private func scheduleNotifications(_ list: [AlarmModel]) {
        let center = UNUserNotificationCenter.current()

            // 기존에 등록된 알림을 모두 취소합니다.
        center.removeAllPendingNotificationRequests()

        list.filter { $0.isEnabled }.forEach { alarm in
            let content       = UNMutableNotificationContent()
            content.title     = alarm.label.isEmpty ? "알람" : alarm.label
            content.body      = "\(alarm.ampmString) \(alarm.timeString)"
            content.sound     = UNNotificationSound(
                named: UNNotificationSoundName(alarm.sound.rawValue + ".mp3"))

                // 매일 같은 시/분에 반복 발화하도록 설정합니다.
            var dateComponents    = DateComponents()
            dateComponents.hour   = alarm.hour
            dateComponents.minute = alarm.minute

                // repeatDays가 비어있어도 매일 반복 설정 (1회성은 추후 개선 가능)
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true)

            let request = UNNotificationRequest(
                identifier: alarm.id.uuidString,
                content: content,
                trigger: trigger)

            center.add(request)
        }
    }

        // MARK: - Snooze

        /// 선택한 알람을 기준으로 N분 뒤에 1회성 다시 알림을 예약합니다.
        /// 저장된 알람 목록은 변경하지 않고, 기존 반복 알림과는 별도로 동작합니다.
    func scheduleSnooze(alarm: AlarmModel, afterMinutes minutes: Int) {
        let seconds = max(1, minutes * 60)
        let content       = UNMutableNotificationContent()
        content.title     = alarm.label.isEmpty ? "알람" : alarm.label
        content.body      = "\(alarm.ampmString) \(alarm.timeString) — 다시 알림"
        content.sound     = UNNotificationSound(
            named: UNNotificationSoundName(alarm.sound.rawValue + ".mp3"))

            // 동일 알람의 여러 스누즈가 겹치지 않도록 고유 식별자 구성
        let identifier = alarm.id.uuidString + "_snooze_" + String(Int(Date().timeIntervalSince1970))

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
