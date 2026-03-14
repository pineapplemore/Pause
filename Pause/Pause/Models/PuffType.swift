//
//  PuffType.swift
//  Pause
//
//  屁屁类型定义（存储用 rawValue，界面用 displayName）
//

import SwiftUI

enum PuffType: String, CaseIterable, Identifiable, Codable {
    case stinky = "臭屁"
    case silent = "闷屁"
    case rapid = "突突突屁"
    case loud = "响屁"
    case hot = "热屁"
    case cold = "寒屁"
    case afterSpicy = "吃辣后"
    case afterIceWater = "喝冰水后"
    
    var id: String { rawValue }
    
    /// 界面显示名：中文 巨臭屁 / 英文 Very stinky 等
    func displayName(isChinese: Bool) -> String {
        if isChinese {
            switch self {
            case .stinky: return "巨臭屁"
            case .silent: return "闷屁"
            case .rapid: return "连环屁"
            case .loud: return "响屁"
            case .hot: return "热屁"
            case .cold: return "寒屁"
            case .afterSpicy: return "吃辣后"
            case .afterIceWater: return "喝冰水后"
            }
        } else {
            switch self {
            case .stinky: return "Very stinky"
            case .silent: return "Silent"
            case .rapid: return "Chain"
            case .loud: return "Loud"
            case .hot: return "Hot"
            case .cold: return "Cold"
            case .afterSpicy: return "After spicy"
            case .afterIceWater: return "After ice water"
            }
        }
    }
    
    var icon: String {
        switch self {
        case .stinky: return "wind"
        case .silent: return "cloud"
        case .rapid: return "bolt.fill"
        case .loud: return "speaker.wave.2.fill"
        case .hot: return "flame.fill"
        case .cold: return "snowflake"
        case .afterSpicy: return "flame"
        case .afterIceWater: return "drop.fill"
        }
    }
    
    /// 莫兰迪柔和绿系配色（低饱和、偏灰）
    var color: Color {
        switch self {
        case .stinky: return Color(red: 0.55, green: 0.58, blue: 0.48)
        case .silent: return Color(red: 0.58, green: 0.52, blue: 0.62)
        case .rapid: return Color(red: 0.45, green: 0.55, blue: 0.62)
        case .loud: return Color(red: 0.42, green: 0.58, blue: 0.58)
        case .hot: return Color(red: 0.65, green: 0.52, blue: 0.48)
        case .cold: return Color(red: 0.48, green: 0.58, blue: 0.60)
        case .afterSpicy: return Color(red: 0.62, green: 0.48, blue: 0.40)
        case .afterIceWater: return Color(red: 0.42, green: 0.58, blue: 0.65)
        }
    }
}
