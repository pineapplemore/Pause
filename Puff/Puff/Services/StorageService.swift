//
//  StorageService.swift
//  Puff
//
//  本地持久化；与小组件通过 App Group 共享数据。
//

import Foundation
import WidgetKit

/// App Group ID，主应用与 Widget 扩展需在 Capabilities 中勾选同一 Group
let kPuffAppGroupSuiteName = "group.com.puff.app"

/// 小组件常用标签最多 3 个，存 tagId（PuffType.rawValue 或 "custom:名称"）
private let kWidgetFavoriteTagIds = "widget_favorite_tag_ids"
/// 小组件常用标签的显示名（与 ids 顺序一致），用于显示「连环屁」等
private let kWidgetFavoriteTagLabels = "widget_favorite_tag_labels"
/// 用户选择的界面语言，小组件用于显示名称与描述（true=中文）
let kPuffAppLanguageIsChinese = "Puff.appLanguageIsChinese"

final class StorageService {
    static let shared = StorageService()
    private let key = "puff_records"
    private let defaults: UserDefaults = {
        UserDefaults(suiteName: kPuffAppGroupSuiteName) ?? UserDefaults.standard
    }()
    
    private init() {}
    
    /// 小组件上显示的 3 个常用标签 ID（在 App 设定里选择）
    func widgetFavoriteTagIds() -> [String] {
        defaults.stringArray(forKey: kWidgetFavoriteTagIds) ?? []
    }
    
    func setWidgetFavoriteTagIds(_ ids: [String]) {
        let capped = Array(ids.prefix(3))
        defaults.set(capped, forKey: kWidgetFavoriteTagIds)
    }
    
    /// 小组件常用标签的显示名（与 ids 顺序一致）
    func widgetFavoriteTagLabels() -> [String] {
        defaults.stringArray(forKey: kWidgetFavoriteTagLabels) ?? []
    }
    
    func setWidgetFavoriteTagLabels(_ labels: [String]) {
        let capped = Array(labels.prefix(3))
        defaults.set(capped, forKey: kWidgetFavoriteTagLabels)
    }
    
    /// 供小组件读取：当前是否为中文（与 App 内用户选择一致）
    func appLanguageIsChinese() -> Bool {
        if defaults.object(forKey: kPuffAppLanguageIsChinese) == nil { return true }
        return defaults.bool(forKey: kPuffAppLanguageIsChinese)
    }
    
    func setAppLanguageIsChinese(_ isChinese: Bool) {
        defaults.set(isChinese, forKey: kPuffAppLanguageIsChinese)
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
    }
    
    func addRecord(_ record: PuffRecord) {
        var list = loadRecords()
        list.insert(record, at: 0)
        saveRecords(list)
        WidgetCenter.shared.reloadAllTimelines()
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
    
    /// 按小时聚合（0...23），用于时段折线图
    func hourlyCounts(for dates: [Date]) -> [Int] {
        let cal = Calendar.current
        var counts = Array(repeating: 0, count: 24)
        for date in dates {
            for record in records(on: date) {
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
}
