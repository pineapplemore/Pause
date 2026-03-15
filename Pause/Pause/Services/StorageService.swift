//
//  StorageService.swift
//  Pause
//
//  本地持久化；与小组件通过 App Group 共享数据。
//

import Foundation
import WidgetKit

/// App Group ID，主应用与 Widget 扩展需在 Capabilities 中勾选同一 Group
let kPauseAppGroupSuiteName = "group.com.yangzhao.pause.app"

/// 4 个行为按键的显示名（顺序与 Behavior.ids 一致）
private let kBehaviorNames = "Pause.behaviorNames"

/// 小组件常用标签最多 3 个，存 tagId（Behavior id: b1~b4）
private let kWidgetFavoriteTagIds = "widget_favorite_tag_ids"
/// 小组件常用标签的显示名（与 ids 顺序一致），用于显示「连环屁」等
private let kWidgetFavoriteTagLabels = "widget_favorite_tag_labels"
/// 用户选择的界面语言，小组件用于显示名称与描述（true=中文）
let kPauseAppLanguageIsChinese = "Pause.appLanguageIsChinese"
/// 小组件按键右下角是否显示用户自定义首字
private let kShowInitialOnWidget = "Pause.showInitialOnWidget"
/// 小组件 1～4 个行为各自的自定义首字（空表示不显示）
private let kWidgetBehaviorInitials = "Pause.widgetBehaviorInitials"
/// 主页是否显示「今日次数」模块（默认 true）
private let kShowCountOnHome = "Pause.showCountOnHome"

final class StorageService {
    static let shared = StorageService()
    private let key = "pause_records"
    private let defaults: UserDefaults = {
        UserDefaults(suiteName: kPauseAppGroupSuiteName) ?? UserDefaults.standard
    }()
    
    private init() {}

    /// 当前启用的行为名称（1～4 个）；首次安装无存储时返回 1 个默认；若存的是旧版 4 项预设则迁移为 1 个
    func behaviorNames() -> [String] {
        let stored = defaults.stringArray(forKey: kBehaviorNames) ?? []
        let isChinese = appLanguageIsChinese()
        if stored.isEmpty {
            return [Behavior.defaultFirstBehaviorName(isChinese: isChinese)]
        }
        // 迁移：若仍是旧版 4 项预设，改为只保留 1 个预设
        let legacy4 = Behavior.legacyPreset4(isChinese: isChinese)
        if stored == legacy4 {
            let one = [Behavior.defaultFirstBehaviorName(isChinese: isChinese)]
            defaults.set(one, forKey: kBehaviorNames)
            WidgetCenter.shared.reloadAllTimelines()
            return one
        }
        // 不再把空字符串替换为默认名，否则用户清空输入时会自动恢复为「咬指甲」
        return stored
    }

    /// 设置行为名称列表（至少 1 个，最多 4 个）；写入后 synchronize 确保下次打开能记住
    func setBehaviorNames(_ names: [String]) {
        var list = names.isEmpty ? [Behavior.defaultFirstBehaviorName(isChinese: appLanguageIsChinese())] : names
        list = Array(list.prefix(Behavior.maxCount))
        defaults.set(list, forKey: kBehaviorNames)
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 小组件上显示的行为 ID（最多 4 个，与主页一致）
    func widgetFavoriteTagIds() -> [String] {
        defaults.stringArray(forKey: kWidgetFavoriteTagIds) ?? []
    }
    
    func setWidgetFavoriteTagIds(_ ids: [String]) {
        let capped = Array(ids.prefix(4))
        defaults.set(capped, forKey: kWidgetFavoriteTagIds)
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// 小组件行为显示名（与 ids 顺序一致）
    func widgetFavoriteTagLabels() -> [String] {
        defaults.stringArray(forKey: kWidgetFavoriteTagLabels) ?? []
    }
    
    func setWidgetFavoriteTagLabels(_ labels: [String]) {
        let capped = Array(labels.prefix(4))
        defaults.set(capped, forKey: kWidgetFavoriteTagLabels)
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// 供小组件读取：当前是否为中文（与 App 内用户选择一致）
    func appLanguageIsChinese() -> Bool {
        if defaults.object(forKey: kPauseAppLanguageIsChinese) == nil { return true }
        return defaults.bool(forKey: kPauseAppLanguageIsChinese)
    }
    
    func setAppLanguageIsChinese(_ isChinese: Bool) {
        defaults.set(isChinese, forKey: kPauseAppLanguageIsChinese)
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func showInitialOnWidget() -> Bool {
        defaults.bool(forKey: kShowInitialOnWidget)
    }

    func setShowInitialOnWidget(_ value: Bool) {
        defaults.set(value, forKey: kShowInitialOnWidget)
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 每个行为槽位的自定义首字（最多 4 个；空字符串表示未设置）
    func widgetBehaviorInitials() -> [String] {
        let list = defaults.stringArray(forKey: kWidgetBehaviorInitials) ?? []
        return (0..<Behavior.maxCount).map { i in
            i < list.count ? String(list[i].prefix(1)) : ""
        }
    }

    func setWidgetBehaviorInitial(at index: Int, initial: String) {
        var list = widgetBehaviorInitials()
        guard index >= 0, index < list.count else { return }
        list[index] = String(initial.prefix(1))
        defaults.set(list, forKey: kWidgetBehaviorInitials)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 批量写入首字并刷新小组件（供「保存到小组件」使用）；先写开关与首字，synchronize 后只 reload 一次
    func setWidgetBehaviorInitials(_ initials: [String]) {
        let list = (0..<Behavior.maxCount).map { i in
            i < initials.count ? String(initials[i].prefix(1)) : ""
        }
        defaults.set(list, forKey: kWidgetBehaviorInitials)
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 一次性写入小组件开关与首字并刷新（避免先写开关触发 reload 时小组件仍读到旧首字或旧开关）
    func saveWidgetInitials(showInitial: Bool, initials: [String]) {
        defaults.set(showInitial, forKey: kShowInitialOnWidget)
        let list = (0..<Behavior.maxCount).map { i in
            i < initials.count ? String(initials[i].prefix(1)) : ""
        }
        defaults.set(list, forKey: kWidgetBehaviorInitials)
        defaults.synchronize()
        // 延迟刷新，确保 App Group 写入对小组件扩展进程可见后再请求新 timeline（新机型如 iPhone 17 需稍长延迟）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            WidgetCenter.shared.reloadTimelines(ofKind: "PauseWidget")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 主页是否显示今日次数模块（默认 true）
    func showCountOnHome() -> Bool {
        if defaults.object(forKey: kShowCountOnHome) == nil { return true }
        return defaults.bool(forKey: kShowCountOnHome)
    }

    func setShowCountOnHome(_ value: Bool) {
        defaults.set(value, forKey: kShowCountOnHome)
        defaults.synchronize()
    }

    func loadRecords() -> [PuffRecord] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([PuffRecord].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.timestamp > $1.timestamp }
    }
    
    func saveRecords(_ records: [PuffRecord]) {
        let data = (try? JSONEncoder().encode(records)) ?? Data()
        defaults.set(data, forKey: key)
        defaults.synchronize()
    }
    
    func addRecord(_ record: PuffRecord) {
        var list = loadRecords()
        list.insert(record, at: 0)
        saveRecords(list)
        WidgetCenter.shared.reloadAllTimelines()
        // 延迟再刷一次小组件，确保 App Group 写入对扩展进程可见后再请求新 timeline
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            WidgetCenter.shared.reloadTimelines(ofKind: "PauseWidget")
        }
    }
    
    func deleteRecord(id: UUID) {
        var list = loadRecords()
        list.removeAll { $0.id == id }
        saveRecords(list)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateRecord(id: UUID, typeIds: [String]) {
        var list = loadRecords()
        guard let idx = list.firstIndex(where: { $0.id == id }) else { return }
        var rec = list[idx]
        rec.typeIds = typeIds
        list[idx] = rec
        saveRecords(list)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func record(byId id: UUID) -> PuffRecord? {
        loadRecords().first { $0.id == id }
    }
    
    func records(on date: Date) -> [PuffRecord] {
        let cal = Calendar.current
        return loadRecords().filter { cal.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    func records(from start: Date, to end: Date) -> [PuffRecord] {
        loadRecords().filter { $0.timestamp >= start && $0.timestamp <= end }
    }
    
    func count(on date: Date) -> Int {
        records(on: date).count
    }
    
    /// 按小时聚合（0...23）；behaviorId 为 nil 时统计全部，否则只统计该行为的记录
    func hourlyCounts(for dates: [Date], behaviorId: String? = nil) -> [Int] {
        let cal = Calendar.current
        var counts = Array(repeating: 0, count: 24)
        for date in dates {
            let list = records(on: date)
            for record in list {
                if let bid = behaviorId {
                    guard record.typeIds.contains(bid) else { continue }
                }
                let hour = cal.component(.hour, from: record.timestamp)
                counts[hour] += 1
            }
        }
        return counts
    }
    
    /// 周期内各标签出现次数 [(tagId, count)]
    func tagDistribution(from start: Date, to end: Date) -> [(String, Int)] {
        let list = records(from: start, to: end)
        var dict: [String: Int] = [:]
        for rec in list {
            for id in rec.typeIds {
                dict[id, default: 0] += 1
            }
        }
        return dict.sorted { $0.value > $1.value }
    }
    
    /// 从今天起连续有记录的天数（含今天）
    func consecutiveRecordDays(from today: Date = Date()) -> Int {
        let cal = Calendar.current
        var d = cal.startOfDay(for: today)
        var count = 0
        while count < 365 {
            if records(on: d).isEmpty { break }
            count += 1
            guard let next = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = next
        }
        return count
    }
    
    /// 高峰小时（0-23），若有并列取第一个
    func peakHour(from dates: [Date]) -> Int? {
        let counts = hourlyCounts(for: dates)
        guard let maxVal = counts.max(), maxVal > 0 else { return nil }
        return counts.firstIndex(of: maxVal)
    }

    /// 周期内每日、每行为 b1～b4 的计数，用于统计页多行为折线
    func behaviorCountsPerDay(from start: Date, to end: Date) -> [(date: Date, counts: [String: Int])] {
        let cal = Calendar.current
        var d = cal.startOfDay(for: start)
        var result: [(Date, [String: Int])] = []
        while d <= end {
            let list = records(on: d)
            var counts: [String: Int] = [:]
            for rec in list {
                for id in rec.typeIds where Behavior.ids.contains(id) {
                    counts[id, default: 0] += 1
                }
            }
            result.append((d, counts))
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        return result
    }
}
