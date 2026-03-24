//
//  AlarmViewModel.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.23.
//

import UIKit
import UserNotifications
import RxSwift
import RxRelay
import SnapKit
import Then

final class AlarmViewModel {

    let alarmList = BehaviorRelay<[Alarm]>(value: [])

    let formattor = DateFormatter().then {
        $0.dateFormat = "yyyy/MM/dd HH:mm"
        $0.locale = Locale(identifier: "ko_KR")  // 수정됨
    }
}

