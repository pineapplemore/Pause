//
//  Behavior.swift
//  Pause
//
//  行为按键：最多 4 个，用于主页一键记录。
//

import Foundation
import SwiftUI

/// 固定 4 个行为槽位，id 为 b1, b2, b3, b4；用户可配置 1～4 个，首次安装仅 1 个默认
enum Behavior {
    /// 莫兰迪配色（与主页按键、日历圆点一致）：避免偏灰，保持可点击感
    static let morandiColors: [Color] = [
        Color(red: 0.45, green: 0.62, blue: 0.58),  // 1: 青绿
        Color(red: 0.48, green: 0.54, blue: 0.72),  // 2: 灰蓝（偏蓝不偏灰）
        Color(red: 0.70, green: 0.52, blue: 0.56),  // 3: 豆沙粉
        Color(red: 0.52, green: 0.64, blue: 0.48)   // 4: 橄榄绿
    ]
    /// 按键渐变用深色
    static let morandiDarkColors: [Color] = [
        Color(red: 0.38, green: 0.52, blue: 0.50),
        Color(red: 0.38, green: 0.44, blue: 0.60),
        Color(red: 0.58, green: 0.42, blue: 0.46),
        Color(red: 0.42, green: 0.52, blue: 0.40)
    ]
    static func morandiColor(at index: Int) -> Color {
        morandiColors[index % morandiColors.count]
    }
    static func morandiDarkColor(at index: Int) -> Color {
        morandiDarkColors[index % morandiDarkColors.count]
    }
    static let maxCount = 4
    static let ids = ["b1", "b2", "b3", "b4"]

    /// 首次安装时的唯一默认行为名
    static func defaultFirstBehaviorName(isChinese: Bool) -> String {
        isChinese ? "咬指甲" : "Nail biting"
    }

    /// 预设：仅 1 个行为（用户点击「恢复预设」恢复为一个按钮）
    static func presetNames(isChinese: Bool) -> [String] {
        [defaultFirstBehaviorName(isChinese: isChinese)]
    }

    /// 旧版 4 项预设（用于迁移：若当前存的是这个，自动改为 1 个）
    static func legacyPreset4(isChinese: Bool) -> [String] {
        if isChinese { return ["反复洗手", "拔毛发", "咬指甲", "咬嘴唇"] }
        return ["Hand washing", "Hair pulling", "Nail biting", "Lip biting"]
    }

    /// 默认显示名（未自定义时）
    static func defaultName(id: String, isChinese: Bool) -> String {
        guard let idx = ids.firstIndex(of: id) else { return id }
        if isChinese { return "行为\(idx + 1)" }
        return "Behavior \(idx + 1)"
    }
}
