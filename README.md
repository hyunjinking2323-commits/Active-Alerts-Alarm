📱 Check It NOW!
High-Precision iOS Utility: Alarm, StopWatch, & Timer
RxSwift 기반의 반응형 프로그래밍과 MVVM 아키텍처를 결합하여 사용자에게 심리스(Seamless)하고 정교한 시간 관리 경험을 제공하는 iOS 유틸리티 앱입니다.

📸 Preview
알람 (Alarm)	스톱워치 (Stopwatch)	타이머 (Timer)
실제 앱 실행 화면(GIF/이미지)을 이곳에 배치하면 시각적 설득력이 높아집니다.

🚀 Key Highlights
Transform 기반 I/O Modeling: RxSwift를 활용한 단방향 데이터 흐름 설계로 상태 관리의 신뢰성과 테스트 용이성을 확보했습니다.

Seamless Core Animation: presentationLayer() 캡처 기법을 통해 일시정지/재개 시에도 끊김 없는 60fps Circular Progress UI를 구현했습니다.

High-Reliability Audio: AVAudioSession 정밀 제어로 무음 모드 및 백그라운드 환경에서도 누락 없는 알람 시스템을 구축했습니다.

User-Centric UX: 드래그 인터랙션으로 종료 시간을 즉각 연장하는 Interactive Timer Finish View를 설계하여 직관성을 높였습니다.

🛠 Tech Stack
Category	Technology
Language	Swift 5.10
Framework	UIKit (Programmatic UI)
Reactive	RxSwift, RxCocoa, RxRelay
Layout	SnapKit, Then
Architecture	MVVM with Transform-based I/O Modeling
Persistence	CoreData, UserDefaults (JSON Serialization)
Media/System	AVFoundation, UserNotifications, AudioToolbox
🏗 Directory Structure
Plaintext
CheckItNOW
├── App (AppDelegate, SceneDelegate, AppAppearance)
├── Models (AlarmModel, TimerModel, SoundModel)
├── ViewModels (AlarmViewModel, TimerViewModel, StopWatchViewModel)
└── Views
    ├── Alarm (AlarmViewController, AlarmCell, AddAlarmViewController)
    ├── StopWatch (StopWatchViewController, LapCell)
    └── Timer (TimerViewController, TimerCell, CircularProgressView)
🔥 Technical Challenges & Solutions
1. 고정밀 타이머 애니메이션 연속성 확보
Problem: 타이머를 일시정지하거나 재시작할 때 애니메이션이 초기 위치로 리셋되거나 흐름이 끊기는 현상 발생.

Cause: 애니메이션 재시작 시 렌더링 트리의 현재 상태값이 아닌, 모델의 속성값을 기준으로 새 애니메이션이 생성되기 때문임.

Solution: presentationLayer()를 통해 렌더링 트리의 실시간 strokeStart 값을 캡처하여 애니메이션의 fromValue로 지정. 이를 통해 어떤 시점에서든 연속성 있는 애니메이션을 보장했습니다.

Optimization: CATransaction을 활용해 리셋 시 발생하는 암시적 애니메이션(Implicit Animation)을 차단하여 즉각적인 UI 반응성을 확보했습니다.

2. 하드웨어 레벨의 신뢰성 높은 알람 시스템
Challenge: 앱이 백그라운드에 있거나 사용자가 무음 모드를 활성화했을 때 알람이 울리지 않을 가능성 대응.

Solution: * AVAudioSession.Category.playback과 .mixWithOthers 옵션을 조합하여 시스템 설정에 관계없이 사운드가 출력되도록 설계.

Fallback Strategy: 커스텀 MP3 리소스 로드 실패 시 AudioServicesPlaySystemSound를 통해 시스템 기본음이 출력되도록 이중화 로직 구현.

UNCalendarNotificationTrigger를 활용해 앱 종료 상태에서도 정확한 시간에 로컬 알림이 트리거되도록 처리했습니다.

3. Reactive UI의 메모리 누수 및 구독 중첩 방지
Challenge: TableView Cell 재사용 시 기존 구독이 유지되어, 이벤트가 중복 방출되거나 메모리 사용량이 증가하는 문제.

Solution: 셀의 prepareForReuse() 시점에서 DisposeBag을 초기화하는 패턴을 엄격히 적용하여, 셀이 재사용될 때마다 이전 구독을 명확히 제거했습니다.

💻 Code Snippet: I/O Modeling
ViewModel의 비즈니스 로직을 Input과 Output으로 명확히 분리하여 데이터 흐름을 한눈에 파악할 수 있도록 설계했습니다.

Swift
func transform(input: Input) -> Output {
    let timerState = BehaviorRelay<TimerState>(value: .setting)
    
    // 시작/일시정지 로직 처리
    input.startPause
        .subscribe(onNext: { _ in
            let currentState = timerState.value
            timerState.accept(currentState == .running ? .paused : .running)
        })
        .disposed(by: disposeBag)

    return Output(
        timeText: timeTextRelay.asDriver(),
        progress: progressRelay.asDriver(),
        timerState: timerState.asDriver()
    )
}
