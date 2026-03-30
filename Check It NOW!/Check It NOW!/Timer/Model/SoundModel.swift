    //
    //  SoundModel.swift
    //  Check It NOW!
    //

import Foundation

    /// 타이머 완료음 데이터 모델
    ///
    /// `Equatable` — RxSwift `rx.modelSelected` 등에서 동등 비교 필요
    /// Alarm 모듈의 `AlarmSound`와 브릿지 역할도 수행
struct SoundModel: Equatable {
    let id:   Int     // 시스템 사운드 ID (AudioToolbox)
    let name: String  // 화면 표시 이름
}
