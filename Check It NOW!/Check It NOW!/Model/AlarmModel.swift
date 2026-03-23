//
//  Alarm.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.23.
//

import UIKit

class Alarm: NSObject, Codable {
    var id: UUID = UUID()
    var date: Date        // 날짜 / 시간
    var isOn: Bool        // 알람이 켜짐 여부
    var title: String     // 원하는 이름
}
