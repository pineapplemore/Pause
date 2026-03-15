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
    /// 1～4 按键与日历圆点一致：紫、橘、湖蓝、玫红
    static let morandiColors: [Color] = [
        Color(red: 0.55, green: 0.40, blue: 0.72),  // 1: 紫色
        Color(red: 0.92, green: 0.52, blue: 0.25), // 2: 橘色
        Color(red: 0.22, green: 0.58, blue: 0.82), // 3: 湖蓝
        Color(red: 0.88, green: 0.32, blue: 0.48)  // 4: 玫红
    ]
    /// 按键渐变用深色
    static let morandiDarkColors: [Color] = [
        Color(red: 0.45, green: 0.30, blue: 0.62),
        Color(red: 0.78, green: 0.42, blue: 0.18),
        Color(red: 0.15, green: 0.45, blue: 0.68),
        Color(red: 0.72, green: 0.24, blue: 0.38)
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
