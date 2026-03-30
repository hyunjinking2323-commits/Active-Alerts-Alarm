# ⏰ Check It NOW!

> 알람을 끄려면 미션을 풀어야 하는 종합 시계 유틸리티 앱

<br>
**팀명** 현지니예~  
**팀 목표** MVVM 아키텍처와 RxSwift를 사용하여 깔끔한 코드를 작성하고 UI 상태 관리의 복잡도를 낮추기ㅊ

<br>

## 👤 팀 정보

| 이름 | 역할 | GitHub |
|:---:|:---:|:---:|
| 우현진 | iOS Developer | [@hyunjinking2323](https://github.com/hyunjinking2323-commits) |

<br>

## 📅 개발 기간

2026.03.20 ~ 2026.03.30 (11일)

<br>

## 🎯 기획 의도

아침에 알람을 끄고 다시 자는 습관을 고치기 위해 만들었습니다.  
알람을 끄려면 미션을 풀어야 하고, 풀지 않으면 최대 볼륨으로 계속 울립니다.

<br>

## 🛠 기술 스택

| 분류 | 사용 기술 |
|:---:|:---:|
| Language | Swift |
| UI | UIKit, SnapKit 5.7.1 |
| Reactive | RxSwift 6.10.2, RxCocoa |
| Architecture | MVVM (Input/Output 패턴) |
| Notification | UNUserNotificationCenter |
| Storage | CoreData |
| Minimum | iOS 16.6 |
| IDE | Xcode 16.3 |

<br>

## 📂 폴더 구조
```
CheckItNOW
├── App
│   ├── AppDelegate.swift
│   └── AppAppearance.swift
├── Alarm
│   ├── Model
│   │   └── AlarmModel.swift
│   ├── View
│   │   ├── AlarmViewController.swift
│   │   └── AlarmCell.swift
│   └── ViewModel
│       └── AlarmViewModel.swift
├── Stopwatch
│   ├── View
│   │   └── StopwatchViewController.swift
│   └── ViewModel
│       └── StopwatchViewModel.swift
├── Timer
│   ├── Model
│   │   ├── TimerModel.swift
│   │   ├── ActiveTimer.swift
│   │   └── TimerState.swift
│   ├── View
│   │   ├── TimerListViewController.swift
│   │   ├── TimerCell.swift
│   │   └── TimerFinishView.swift
│   └── ViewModel
│       └── TimerViewModel.swift
└── Common
    └── CircularProgressView.swift
```

<br>

## ✅ 구현 기능

### 필수 구현

- [x] MVVM 디자인 패턴 적용
- [x] 알람 추가 · 수정 · 삭제
- [x] 알람 ON/OFF 스위치
- [x] 알람 반복 요일 · 레이블 · 사운드 설정
- [x] 지정 시각 알람 사운드 재생
- [x] 스톱워치 (시작 · 일시정지 · 재개 · 초기화)
- [x] 스톱워치 랩 기록 (최단/최장 하이라이트)
- [x] 타이머 시간 설정
- [x] 타이머 완료 시 사운드 재생

### 도전 구현

- [x] 원형 Progress Bar (CAShapeLayer strokeStart 애니메이션)
- [x] 다중 타이머 동시 실행 (UUID 기반 ActiveTimer)

<br>

## 💡 핵심 구현 포인트

### MVVM Input/Output 패턴

모든 ViewModel에 Input/Output 구조체를 정의해서 데이터 흐름을 단방향으로 관리했습니다.
```swift
struct Input {
    let toggleAlarm: Observable<(AlarmModel, Bool)>
    let addAlarm: Observable<AlarmModel>
    let deleteAlarm: Observable<IndexPath>
}

struct Output {
    let alarms: Driver<[AlarmModel]>
    let nextAlarmCountdown: Driver<String>
}

func transform(input: Input) -> Output {
    input.toggleAlarm
        .withUnretained(self)
        .subscribe(onNext: { owner, pair in
            let (alarm, isOn) = pair
            isOn
                ? owner.scheduleNotification(for: alarm)
                : UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(
                        withIdentifiers: [alarm.id.uuidString]
                    )
        })
        .disposed(by: disposeBag)

    return Output(
        alarms: alarmsRelay.asDriver(),
        nextAlarmCountdown: countdownRelay.asDriver()
    )
}
```

### 다중 타이머 — ActiveTimer 구조체

타이머마다 UUID를 부여해서 동시 실행과 개별 알림 관리가 가능하도록 설계했습니다.
```swift
struct ActiveTimer {
    let id: UUID
    let timerModel: TimerModel
    var remainingSeconds: Int
    var timer: Timer?
    var notificationID: String { id.uuidString }
}
```

### 원형 Progress Bar — strokeStart 애니메이션

`strokeEnd` 대신 `strokeStart`를 0 → 1로 애니메이션해서 시계 방향으로 줄어드는 효과를 구현했습니다.
```swift
func setProgress(_ progress: CGFloat) {
    let anim = CABasicAnimation(keyPath: "strokeStart")
    anim.fromValue = progressLayer.strokeStart
    anim.toValue   = progress
    anim.duration  = 0.4
    progressLayer.add(anim, forKey: "progress")
    progressLayer.strokeStart = progress
}
```

### CADisplayLink 기반 스톱워치

일반 `Timer` 대신 `CADisplayLink`를 사용해 드리프트 없는 1/100초 측정을 구현했습니다.
```swift
func startDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(tick))
    displayLink?.add(to: .main, forMode: .common)
}

@objc func tick() {
    elapsed = CACurrentMediaTime() - startTime
    let minutes    = Int(elapsed) / 60
    let seconds    = Int(elapsed) % 60
    let hundredths = Int(elapsed * 100) % 100
    timeRelay.accept(
        String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    )
}
```

<br>

## 🐛 트러블슈팅

### 1. performBatchUpdates 타이밍 크래시

**문제** UIKit이 블록 실행 전에 행 수를 스냅샷해두기 때문에, 블록 안에서 데이터소스를 변경하면 count 불일치로 크래시 발생  
**해결** `reloadData()`로 교체, `rx.items`와 수동 reload 혼용을 `combineLatest + map` 파이프라인으로 통일

### 2. 셀 ViewModel 공유로 인한 상태 동기화 버그

**문제** 여러 셀이 동일한 ViewModel 인스턴스를 참조해서, 한 셀 변경이 전체 셀에 반영  
**해결** `configure(with:)` 호출 시 각 셀마다 새 ViewModel 인스턴스를 생성·주입

### 3. TimerState 순환 참조 컴파일 에러

**문제** `TimerCell` ↔ `TimerViewModel` 상호 import 구조로 인한 순환 의존성  
**해결** `TimerState`를 별도 파일의 top-level enum으로 분리

### 4. 탭 전환 시 NavigationBar 색상 초기화

**문제** 탭 전환마다 커스텀 appearance가 리셋되어 검정 배경이 사라짐  
**해결** `AppAppearance` enum을 `AppDelegate.didFinishLaunching`에서 한 번만 호출해 전역 고정
```swift
enum AppAppearance {
    static func apply() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = .black
        UINavigationBar.appearance().standardAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tab
    }
}
```
