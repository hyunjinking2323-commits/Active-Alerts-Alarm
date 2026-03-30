//
//   AlarmSound.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.26.
//


import Foundation
import AVFoundation

    /// 알람에서 사용할 수 있는 소리 목록
    ///
    /// `rawValue` = 번들 내 mp3 파일명
    /// 파일이 없으면 `systemSoundID`로 시스템 사운드 fallback
enum AlarmSound: String, CaseIterable, Codable {
    case radar          = "Radar"
    case chimes         = "Chimes"
    case circuit        = "Circuit"
    case constellation  = "Constellation"
    case cosmic         = "Cosmic"
    case crystals       = "Crystals"
    case hillside       = "Hillside"
    case illuminate     = "Illuminate"
    case nightOwl       = "Night Owl"
    case playtime       = "Playtime"
    case presto         = "Presto"
    case radiate        = "Radiate"
    case reflect        = "Reflect"
    case ripple         = "Ripple"
    case sencha         = "Sencha"
    case signal         = "Signal"
    case silk           = "Silk"
    case slow_rise      = "Slow Rise"
    case summit         = "Summit"
    case twinkle        = "Twinkle"

        /// 화면에 표시할 이름
    var displayName: String { rawValue }

        /// 시스템 사운드 ID (번들 mp3 없을 때 fallback)
    var systemSoundID: Int {
        switch self {
            case .radar:          return 1005
            case .chimes:         return 1008
            case .circuit:        return 1007
            case .constellation:  return 1009
            case .cosmic:         return 1010
            case .crystals:       return 1013
            case .hillside:       return 1016
            case .illuminate:     return 1020
            case .nightOwl:       return 1021
            case .playtime:       return 1022
            case .presto:         return 1023
            case .radiate:        return 1024
            case .reflect:        return 1025
            case .ripple:         return 1026
            case .sencha:         return 1027
            case .signal:         return 1028
            case .silk:           return 1029
            case .slow_rise:      return 1030
            case .summit:         return 1031
            case .twinkle:        return 1032
        }
    }

        /// Timer 모듈과 공유하는 `SoundModel`로 변환
    var toSoundModel: SoundModel {
        SoundModel(id: systemSoundID, name: displayName)
    }

        /// systemSoundID로 AlarmSound 역탐색
    static func from(soundID: Int) -> AlarmSound {
        allCases.first { $0.systemSoundID == soundID } ?? .radar
    }

        /// 이름 문자열로 AlarmSound 역탐색
    static func from(name: String) -> AlarmSound {
        allCases.first { $0.rawValue == name } ?? .radar
    }
}
