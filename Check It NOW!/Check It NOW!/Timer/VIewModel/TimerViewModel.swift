    //
    //  TimerViewModel.swift
    //  Check It NOW!
    //

import Foundation
import RxSwift
import RxCocoa
import UserNotifications
import AVFoundation

    // MARK: - TimerState

    /// 타이머의 현재 상태
    /// 최상위 타입으로 분리 → TimerCell 등 다른 파일에서 import 없이 참조 가능
enum TimerState {
    case setting  // 설정 (초기/리셋)
    case running  // 카운트다운 중
    case paused   // 일시정지
    case finished // 종료
}

    // MARK: - TimerViewModel

final class TimerViewModel {

        // MARK: - Input / Output

    struct Input {
        let startPause:      PublishRelay<Void>
        let cancel:          PublishRelay<Void>
        let selectedSeconds: PublishRelay<Double>
        let labelText:       PublishRelay<String>
        let openSoundPicker: PublishRelay<Void>
        let selectedSoundID: PublishRelay<Int>
        let deleteTimer:     PublishRelay<UUID>
    }

    struct Output {
        let timeText:             Driver<String>       // 남은 시간 텍스트
        let progress:             Driver<Float>        // 원형 진행 바 (0.0 ~ 1.0)
        let buttonTitle:          Driver<String>       // "시작" / "일시정지"
        let timerState:           Driver<TimerState>   // 현재 상태
        let endTimeText:          Driver<String>       // "🔔 오후 3:45" 형식
        let recentTimers:         Driver<[TimerModel]> // 최근 타이머 목록
        let isSoundPickerVisible: Driver<Bool>         // 소리 시트 표시 여부
        let availableSounds:      Driver<[SoundModel]> // 선택 가능한 사운드 목록
        let selectedSoundName:    Driver<String>       // 현재 선택된 사운드 이름
        let selectedSoundID:      Driver<Int>          // 현재 선택된 사운드 ID
    }

        // MARK: - Properties

    private let disposeBag = DisposeBag()

    private let remainingSeconds:    BehaviorRelay<Double>
    private let state                = BehaviorRelay<TimerState>(value: .setting)
    private let isSoundPickerVisible = BehaviorRelay<Bool>(value: false)

    private var timerDisposable:    Disposable?
    private var autoStopDisposable: Disposable?
    private var totalSeconds:       Double
    private var currentLabel:       String = ""
    private var targetEndDate:      Date?
    private var currentAutoStopSeconds: Int = 30

    private let selectedSoundIDRelay = BehaviorRelay<Int>(value: 1005)
    private let recentTimersRelay    = BehaviorRelay<[TimerModel]>(value: [])

        /// 동시 실행 지원: 인스턴스마다 고유 알림 ID 부여
    private let instanceID = UUID().uuidString
    private var timerNotificationID: String { "timer.notification.\(instanceID)" }

    private let persistenceKey = "recent_timers"

    private let sounds: [SoundModel] = [
        SoundModel(id: 1000, name: "New Mail"),
        SoundModel(id: 1005, name: "Alarm"),
        SoundModel(id: 1007, name: "Tri-tone"),
        SoundModel(id: 1008, name: "Chime"),
        SoundModel(id: 1009, name: "Glass"),
        SoundModel(id: 1010, name: "Horn")
    ]

        /// 완료음 반복 재생 플레이어
        /// AudioServicesPlaySystemSound는 단발성 → AVAudioPlayer로 무한 반복
    private var audioPlayer: AVAudioPlayer?

        // MARK: - Init

    init(seconds: Double = 60) {
        self.totalSeconds     = seconds
        self.remainingSeconds = BehaviorRelay(value: seconds)
        loadRecentTimers()
            // 마지막으로 사용한 사운드 복원
        if let lastSound = recentTimersRelay.value.first {
            selectedSoundIDRelay.accept(lastSound.selectedSoundID)
        }
    }

        // MARK: - Deinit

    deinit {
        cancelTimerNotification()
            // deinit 시 알람 반드시 정지 — 해제 후 소리가 계속 나는 현상 방지
        audioPlayer?.stop()
        audioPlayer = nil
        print("\(Self.self) deinit")
    }

        // MARK: - Transform

    func transform(input: Input) -> Output {
        bindInputs(input)
        return makeOutputs()
    }

        // MARK: - Public

        /// 최근 타이머 저장/업데이트 (TimerListViewController에서 호출)
    func saveTimer(_ newTimer: TimerModel) {
        var timers = recentTimersRelay.value
        if let existingIndex = timers.firstIndex(where: { $0.id == newTimer.id }) {
            timers[existingIndex] = newTimer
        } else {
                // 동일한 시간+레이블 중복 제거 후 맨 앞에 삽입
            timers.removeAll { $0.totalSeconds == newTimer.totalSeconds && $0.label == newTimer.label }
            timers.insert(newTimer, at: 0)
        }
        if timers.count > 5 { timers = Array(timers.prefix(5)) }
        recentTimersRelay.accept(timers)
        persistTimers(timers)
    }

        /// 목록 화면에서 재생 버튼 탭 시 즉시 시작
    func startImmediately(seconds: Double, label: String) {
        totalSeconds = seconds
        currentLabel = label
        remainingSeconds.accept(seconds)
        start()
    }
}

    // MARK: - Input Binding

private extension TimerViewModel {

    func bindInputs(_ input: Input) {
            // 시간 피커 변경
        input.selectedSeconds
            .bind(with: self) { owner, seconds in
                owner.totalSeconds = seconds
                owner.remainingSeconds.accept(seconds)
            }
            .disposed(by: disposeBag)

            // 레이블 텍스트 업데이트
        input.labelText
            .bind(with: self) { owner, label in owner.currentLabel = label }
            .disposed(by: disposeBag)

            // 소리 피커 시트 토글
        input.openSoundPicker
            .bind(with: self) { owner, _ in
                owner.isSoundPickerVisible.accept(!owner.isSoundPickerVisible.value)
            }
            .disposed(by: disposeBag)

            // 사운드 선택 → 미리듣기 (단발)
        input.selectedSoundID
            .bind(with: self) { owner, id in
                owner.selectedSoundIDRelay.accept(id)
                owner.isSoundPickerVisible.accept(false)
                AudioServicesPlaySystemSound(SystemSoundID(id))
            }
            .disposed(by: disposeBag)

            // 시작 / 일시정지 토글
        input.startPause
            .bind(with: self) { owner, _ in
                if owner.state.value != .running,
                   let current = owner.recentTimersRelay.value.first {
                    owner.currentAutoStopSeconds = current.effectiveAutoStopSeconds
                }
                owner.state.value == .running ? owner.pause() : owner.start()
            }
            .disposed(by: disposeBag)

            // 취소 → 초기화
        input.cancel
            .bind(with: self) { owner, _ in owner.reset() }
            .disposed(by: disposeBag)

            // 최근 타이머 삭제
        input.deleteTimer
            .bind(with: self) { owner, uuid in
                var timers = owner.recentTimersRelay.value
                timers.removeAll { $0.id == uuid }
                owner.recentTimersRelay.accept(timers)
                owner.persistTimers(timers)
            }
            .disposed(by: disposeBag)
    }
}

    // MARK: - Output Creation

private extension TimerViewModel {

    func makeOutputs() -> Output {
            // 남은 시간 텍스트
        let timeText = remainingSeconds
            .map { TimerViewModel.formatTime($0) }
            .asDriver(onErrorJustReturn: "00:00")

            // 진행률 (1.0 = 꽉 참, 0.0 = 소진)
        let progress = remainingSeconds
            .withUnretained(self)
            .map { owner, seconds -> Float in
                guard owner.totalSeconds > 0 else { return 1.0 }
                return Float(seconds / owner.totalSeconds)
            }
            .asDriver(onErrorJustReturn: 1.0)

        let buttonTitle = state
            .map { $0 == .running ? "일시정지" : "시작" }
            .asDriver(onErrorJustReturn: "시작")

            // 종료 예정 시각 (실행 중일 때만 표시)
        let endTimeText = Driver
            .combineLatest(state.asDriver(), remainingSeconds.asDriver())
            .map { state, seconds -> String in
                guard state == .running else { return "" }
                let end = Date().addingTimeInterval(seconds)
                let f = DateFormatter()
                f.dateFormat = "a h:mm"
                f.locale = Locale(identifier: "ko_KR")
                return "🔔 \(f.string(from: end))"
            }

        let selectedSoundName = selectedSoundIDRelay
            .withUnretained(self)
            .map { owner, id in owner.sounds.first { $0.id == id }?.name ?? "알림음" }
            .asDriver(onErrorJustReturn: "알림음")

        return Output(
            timeText:             timeText,
            progress:             progress,
            buttonTitle:          buttonTitle,
            timerState:           state.asDriver(),
            endTimeText:          endTimeText,
            recentTimers:         recentTimersRelay.asDriver(),
            isSoundPickerVisible: isSoundPickerVisible.asDriver(),
            availableSounds:      Driver.just(sounds),
            selectedSoundName:    selectedSoundName,
            selectedSoundID:      selectedSoundIDRelay.asDriver()
        )
    }
}

    // MARK: - Timer Control

private extension TimerViewModel {

    func start() {
        guard remainingSeconds.value > 0 else { return }

        let isFirstStart = state.value == .setting
        state.accept(.running)
        isSoundPickerVisible.accept(false)
        targetEndDate = Date().addingTimeInterval(remainingSeconds.value)
        scheduleTimerNotification(after: remainingSeconds.value)

        if isFirstStart { saveCurrentAsRecent() }

        timerDisposable?.dispose()
            // 50ms 간격으로 남은 시간 업데이트
        timerDisposable = Observable<Int>
            .interval(.milliseconds(50), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self, let target = targetEndDate else { return }
                let timeLeft = target.timeIntervalSince(Date())
                if timeLeft <= 0 {
                    remainingSeconds.accept(0)
                    timerDisposable?.dispose()
                    timerDisposable = nil
                    targetEndDate = nil
                    state.accept(.finished)
                    playCompletionSound()
                    scheduleAutoStop()
                } else {
                    remainingSeconds.accept(timeLeft)
                }
            })
    }

    func pause() {
        state.accept(.paused)
        timerDisposable?.dispose()
        timerDisposable = nil
        targetEndDate   = nil
        cancelTimerNotification()
    }

    func reset() {
        timerDisposable?.dispose()
        timerDisposable    = nil
        targetEndDate      = nil
        autoStopDisposable?.dispose()
        autoStopDisposable = nil
        state.accept(.setting)
        isSoundPickerVisible.accept(false)
        cancelTimerNotification()
        stopCompletionSound()
        remainingSeconds.accept(totalSeconds)
    }

        // MARK: - Sound

        /// 완료음 반복 재생
        /// 시스템 사운드 파일 로드 성공 시 AVAudioPlayer 무한 반복,
        /// 실패 시 AudioServicesPlaySystemSound fallback (단발)
    func playCompletionSound() {
        let soundID = selectedSoundIDRelay.value

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        if let url = systemSoundURL(for: soundID) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1  // 무한 반복
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                return
            } catch {
                print("AVAudioPlayer 로드 실패: \(error)")
            }
        }
        AudioServicesPlaySystemSound(SystemSoundID(soundID))
    }

    func stopCompletionSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

        /// iOS 시스템 사운드 파일 경로 조회 (기기/버전마다 경로 상이)
    private func systemSoundURL(for id: Int) -> URL? {
        let ids:   [Int]    = [1000,           1005,        1007,           1008,        1009,        1010     ]
        let names: [String] = ["new-mail.caf", "alarm.caf", "tri-tone.caf", "chime.caf", "glass.caf", "horn.caf"]

        guard let index = ids.firstIndex(of: id) else { return nil }
        let fileName = names[index]

        let candidates = [
            "/System/Library/Audio/UISounds/\(fileName)",
            "/System/Library/Audio/UISounds/Modern/\(fileName)"
        ]
        return candidates
            .map { URL(fileURLWithPath: $0) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

        // MARK: - Auto Stop

    func saveCurrentAsRecent() {
        let newTimer = TimerModel(
            label: currentLabel,
            totalSeconds: totalSeconds,
            selectedSoundID: selectedSoundIDRelay.value,
            autoStopSeconds: currentAutoStopSeconds == 30 ? nil : currentAutoStopSeconds
        )
        saveTimer(newTimer)
    }

        /// 완료음 울린 후 n초 뒤 자동으로 setting 상태로 복귀
    func scheduleAutoStop() {
        autoStopDisposable?.dispose()
        autoStopDisposable = Observable<Int>
            .timer(.seconds(currentAutoStopSeconds), scheduler: MainScheduler.instance)
            .bind(onNext: { [weak self] _ in
                self?.stopCompletionSound()
                self?.finishTimer()
            })
    }

    private func finishTimer() {
        autoStopDisposable?.dispose()
        autoStopDisposable = nil
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        state.accept(.setting)
        remainingSeconds.accept(totalSeconds)
    }
}

    // MARK: - Persistence

private extension TimerViewModel {

    func persistTimers(_ timers: [TimerModel]) {
        guard let data = try? JSONEncoder().encode(timers) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    func loadRecentTimers() {
        guard
            let data = UserDefaults.standard.data(forKey: persistenceKey),
            let list = try? JSONDecoder().decode([TimerModel].self, from: data)
        else { return }
        recentTimersRelay.accept(list)
    }
}

    // MARK: - Notifications

private extension TimerViewModel {

    func scheduleTimerNotification(after seconds: Double) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [timerNotificationID])

        let content = UNMutableNotificationContent()
        content.title = currentLabel.isEmpty ? "타이머 완료" : currentLabel
        content.body  = "설정한 시간이 끝났어요!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: timerNotificationID, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelTimerNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [timerNotificationID])
    }
}

    // MARK: - Helpers

extension TimerViewModel {

        /// TimeInterval → "MM:SS" 또는 "H:MM:SS" 문자열
    static func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
        ? String(format: "%d:%02d:%02d", h, m, s)
        : String(format: "%02d:%02d", m, s)
    }
}
