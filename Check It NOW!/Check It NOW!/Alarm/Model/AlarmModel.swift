    //
    //  AlarmModel.swift
    //  Check It NOW!
    //
    //  Created by t2025-m0239 on 2026.03.23.
    //

import Foundation

    // MARK: - AlarmSound

    /// 알람 사운드 종류를 정의하는 열거형.
    /// rawValue가 곧 번들 내 mp3 파일명과 일치해야 합니다.
enum AlarmSound: String, CaseIterable, Codable {
    case radar   = "Radar"
    case opening = "Opening"
    case chimes  = "Chimes"
    case digital = "Digital"
    case harp    = "Harp"
    case waves   = "Waves"

        /// 화면에 표시할 사운드 이름 (rawValue와 동일)
    var displayName: String { rawValue }
}

    // MARK: - AlarmModel

    /// 알람 하나를 나타내는 데이터 모델.
    /// Codable을 채택해 UserDefaults에 JSON으로 저장/불러오기가 가능합니다.
struct AlarmModel: Codable, Identifiable {

        /// 알람 고유 식별자. 알람마다 UUID를 자동 부여합니다.
    var id: UUID = UUID()

        /// 알람 시각 - 시 (0~23, 24시간제)
    var hour: Int

        /// 알람 시각 - 분 (0~59)
    var minute: Int

        /// 알람 이름 (예: "기상", "약 먹기")
    var label: String

        /// 알람 활성화 여부. false면 알람이 울리지 않습니다.
    var isEnabled: Bool

        /// 알람 사운드 종류
    var sound: AlarmSound

        /// 반복 요일 배열. 0=일, 1=월, 2=화, 3=수, 4=목, 5=금, 6=토
        /// 빈 배열이면 1회성 알람입니다.
    var repeatDays: [Int]

        /// 다시 알림(스누즈) 활성화 여부.
        /// false면 발화 팝업에서 "다시 알림" 버튼이 표시되지 않습니다.
    var isSnoozeEnabled: Bool
    var snoozeInterval: Int = 15

        // MARK: - Computed Properties

        /// 12시간제 시각 문자열 (예: "7:30", "12:05")
    var timeString: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d", h, minute)
    }

        /// 오전/오후 문자열
    var ampmString: String {
        hour < 12 ? "오전" : "오후"
    }

        /// 셀 하단에 표시되는 반복 요일 요약 문자열.
        /// 매일 / 주중 / 주말 / 개별 요일 / 알람 이름 순으로 판단합니다.
    var repeatLabel: String {
        let names  = ["일", "월", "화", "수", "목", "금", "토"]
        let sorted = repeatDays.sorted()
        if sorted == [0, 1, 2, 3, 4, 5, 6] { return "매일" }
        if sorted == [1, 2, 3, 4, 5]       { return "주중" }
        if sorted == [0, 6]                { return "주말" }
        if sorted.isEmpty                  { return label }
        return sorted.map { names[$0] }.joined(separator: " ")
    }

        // MARK: - Methods

        /// 다음 알람까지 남은 시간을 한국어 문자열로 반환합니다.
        /// 알람이 비활성화 상태이거나 날짜 계산에 실패하면 nil을 반환합니다.
    func nextFireDescription() -> String? {
        guard isEnabled else { return nil }

        let calendar = Calendar.current
        let now      = Date()

            // 오늘 날짜에 알람 시/분을 합쳐 다음 발화 시각을 계산합니다.
        var components    = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour   = hour
        components.minute = minute
        components.second = 0

        guard var nextDate = calendar.date(from: components) else { return nil }

            // 이미 지난 시각이면 내일로 넘깁니다.
        if nextDate <= now {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
        }

        let diff    = Int(nextDate.timeIntervalSince(now))
        let hours   = diff / 3600
        let minutes = (diff % 3600) / 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분 후에 알람이 울립니다"
        }
        return "\(minutes)분 후에 알람이 울립니다"
    }
}
