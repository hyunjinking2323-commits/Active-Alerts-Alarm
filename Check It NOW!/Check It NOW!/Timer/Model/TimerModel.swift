    //
    //  TimerModel.swift
    //  Check It NOW!
    //

import Foundation

    /// 타이머 한 건의 데이터를 표현하는 값 타입
    ///
    /// 모델은 순수 데이터만 담아 `Codable` 직렬화를 단순하게 유지합니다.
struct TimerModel: Codable {

        // MARK: - Stored Properties

    let id: UUID
    var label: String         // 예: "Coffee", "라면"
    var totalSeconds: Double  // 총 시간 (초)
    var selectedSoundID: Int  // 완료음 systemSoundID
    var autoStopSeconds: Int? // nil = 자동 종료 없음

        // MARK: - Init (새 타이머)

    init(
        label: String = "",
        totalSeconds: Double,
        selectedSoundID: Int = 1005,
        autoStopSeconds: Int? = nil
    ) {
        self.id              = UUID()
        self.label           = label
        self.totalSeconds    = totalSeconds
        self.selectedSoundID = selectedSoundID
        self.autoStopSeconds = autoStopSeconds
    }

        // MARK: - Init (편집 — 기존 id 보존)

    init(
        copying existing: TimerModel,
        label: String,
        totalSeconds: Double,
        selectedSoundID: Int,
        autoStopSeconds: Int? = nil
    ) {
        self.id              = existing.id
        self.label           = label
        self.totalSeconds    = totalSeconds
        self.selectedSoundID = selectedSoundID
        self.autoStopSeconds = autoStopSeconds
    }

        // MARK: - Computed Properties

        /// 자동 종료 시간 — nil이면 기본값 30초
    var effectiveAutoStopSeconds: Int {
        autoStopSeconds ?? 30
    }

        /// "M:SS" 또는 "H:MM:SS" 형식 시간 문자열
    var timeString: String {
        let total = Int(totalSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
        ? String(format: "%d:%02d:%02d", h, m, s)
        : String(format: "%d:%02d", m, s)
    }
}
