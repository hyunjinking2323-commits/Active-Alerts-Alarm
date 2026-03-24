// AlarmModel.swift
import Foundation

enum AlarmSound: String, CaseIterable, Codable {
    case radar    = "Radar"
    case opening  = "Opening"
    case chimes   = "Chimes"
    case digital  = "Digital"
    case harp     = "Harp"
    case waves    = "Waves"
    var displayName: String { rawValue }
}

struct AlarmModel: Codable, Identifiable {
    var id: UUID = UUID()
    var hour: Int
    var minute: Int
    var label: String
    var isEnabled: Bool
    var sound: AlarmSound
    var repeatDays: [Int]   // 0=일 1=월 ... 6=토

    var timeString: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d", h, minute)
    }
    var ampmString: String { hour < 12 ? "오전" : "오후" }

    var repeatLabel: String {
        let names = ["일","월","화","수","목","금","토"]
        let sorted = repeatDays.sorted()
        if sorted == [0,1,2,3,4,5,6] { return "매일" }
        if sorted == [1,2,3,4,5]     { return "주중" }
        if sorted == [0,6]           { return "주말" }
        if sorted.isEmpty            { return label }
        return sorted.map { names[$0] }.joined(separator: " ")
    }

    func nextFireDescription() -> String? {
        guard isEnabled else { return nil }
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year,.month,.day], from: now)
        comps.hour = hour; comps.minute = minute; comps.second = 0
        guard var next = cal.date(from: comps) else { return nil }
        if next <= now { next = cal.date(byAdding: .day, value: 1, to: next)! }
        let diff = Int(next.timeIntervalSince(now))
        let h = diff / 3600
        let m = (diff % 3600) / 60
        if h > 0 { return "\(h)시간 \(m)분 후에 알람이 울립니다" }
        return "\(m)분 후에 알람이 울립니다"
    }
}
