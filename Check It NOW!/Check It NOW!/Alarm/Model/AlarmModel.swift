    //
    //  AlarmModel.swift
    //  Check It NOW!
    //

import Foundation

    /// 알람 한 건의 데이터를 표현하는 값 타입
    ///
    /// `Codable` — UserDefaults JSON 직렬화 지원
    /// `Identifiable` — RxSwift `rx.items` 등에서 고유 식별 지원
struct AlarmModel: Codable, Identifiable {

        // MARK: - Stored Properties

    let id: UUID
    var time: Date
    var label: String
    var repeatDays: [Int]        // 0 = 일, 1 = 월, … 6 = 토
    var isEnabled: Bool
    var isSnoozeEnabled: Bool
    var snoozeInterval: Int      // 스누즈 반복 간격 (분, 1~30)
    var soundName: String
    var selectedSoundID: Int

        // MARK: - Init

        /// 새 알람 생성 — 기본값 적용
    init(
        time: Date = Date(),
        label: String = "",
        repeatDays: [Int] = [],
        isEnabled: Bool = true,
        isSnoozeEnabled: Bool = true,
        snoozeInterval: Int = 5,
        soundName: String = "Radar",
        selectedSoundID: Int = 1005
    ) {
        self.id             = UUID()
        self.time           = time
        self.label          = label
        self.repeatDays     = repeatDays
        self.isEnabled      = isEnabled
        self.isSnoozeEnabled = isSnoozeEnabled
        self.snoozeInterval = snoozeInterval
        self.soundName      = soundName
        self.selectedSoundID = selectedSoundID
    }

        // MARK: - Computed Properties (UI용)

        /// "12:30" 형식 시간 문자열 (AlarmCell timeLabel 용)
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: time)
    }

        /// "오전" / "오후" 문자열 (AlarmCell ampmLabel 용)
    var ampmString: String {
        let f = DateFormatter()
        f.dateFormat = "a"
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: time)
    }

        /// 반복 요일 + 레이블 복합 표시 (AlarmCell subLabel 용)
    var repeatLabel: String {
        label.isEmpty ? repeatText : "\(repeatText)  \(label)"
    }

        /// 반복 요일 표시 문자열
    var repeatText: String {
        if repeatDays.isEmpty              { return "안 함" }
        if repeatDays.sorted() == [0, 6]  { return "주말" }
        if repeatDays.sorted() == [1,2,3,4,5] { return "평일" }
        if repeatDays.count == 7          { return "매일" }
        let names = ["일","월","화","수","목","금","토"]
        return "매주 " + repeatDays.sorted().map { names[$0] }.joined(separator: ", ")
    }

        /// 스누즈 간격 표시 ("5분마다")
    var snoozeIntervalText: String { "\(snoozeInterval)분마다" }
}
