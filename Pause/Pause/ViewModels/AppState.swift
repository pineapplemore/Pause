//
//  AppState.swift
//  Pause
//

import SwiftUI
import WidgetKit

private let kHasLaunchedBefore = "Pause.hasLaunchedBefore"
private let kLanguageIsChinese = "Pause.languageIsChinese"
private let kHasUserChosenLanguage = "Pause.hasUserChosenLanguage"
private let kCustomTagNames = "Pause.customTagNames"
private let kDeletedDefaultTagIds = "Pause.deletedDefaultTagIds"
private let kShownMilestones = "Pause.shownMilestones"

/// 小彩蛋里程碑档位
private let kMilestones = [10, 50, 100, 500, 1000]

final class AppState: ObservableObject {
    @Published private(set) var records: [PuffRecord] = []
    /// 刚记录的一条的 id，之后点击标签会关联到这条（补标签）
    @Published var lastRecordedId: UUID?
    /// 用户添加的自定义标签名（用于显示和选择）
    @Published var customTagNames: [String] {
        didSet { UserDefaults.standard.set(customTagNames, forKey: kCustomTagNames) }
    }
    /// 用户从列表中“删除”的默认标签 rawValue，不再在主页显示，历史记录仍保留
    @Published var deletedDefaultTagIds: Set<String> {
        didSet { UserDefaults.standard.set(Array(deletedDefaultTagIds), forKey: kDeletedDefaultTagIds) }
    }
    /// 当前是否为中文（首次启动默认英文；若用户曾切换过则记住选择）
    @Published var isChinese: Bool {
        didSet {
            UserDefaults.standard.set(true, forKey: kHasUserChosenLanguage)
            UserDefaults.standard.set(isChinese, forKey: kLanguageIsChinese)
            storage.setAppLanguageIsChinese(isChinese)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    private let storage = StorageService.shared
    
    init() {
        self.customTagNames = UserDefaults.standard.stringArray(forKey: kCustomTagNames) ?? []
        let deleted = UserDefaults.standard.stringArray(forKey: kDeletedDefaultTagIds) ?? []
        self.deletedDefaultTagIds = Set(deleted)
        if UserDefaults.standard.bool(forKey: kHasLaunchedBefore) {
            if UserDefaults.standard.bool(forKey: kHasUserChosenLanguage) {
                self.isChinese = UserDefaults.standard.object(forKey: kLanguageIsChinese) as? Bool ?? false
            } else {
                self.isChinese = false
            }
        } else {
            UserDefaults.standard.set(true, forKey: kHasLaunchedBefore)
            self.isChinese = false
            UserDefaults.standard.set(false, forKey: kLanguageIsChinese)
        }
        storage.setAppLanguageIsChinese(self.isChinese)
        WidgetCenter.shared.reloadAllTimelines()
        refresh()
    }
    
    func addCustomTag(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !customTagNames.contains(trimmed) else { return }
        customTagNames.append(trimmed)
    }
    
    func removeCustomTag(name: String) {
        customTagNames.removeAll { $0 == name }
    }
    
    func removeDefaultTagFromList(rawValue: String) {
        deletedDefaultTagIds.insert(rawValue)
    }
    
    func toggleLanguage() {
        let wasChinese = isChinese
        isChinese.toggle()
        var names = storage.behaviorNames()
        // 仅系统默认名随语言切换；用户自定义名不变。第 1 槽支持「咬指甲」/「Nail biting」，各槽支持「行为N」/「Behavior N」。
        names = (0..<names.count).map { i in
            let name = names[i]
            if i == 0, name == Behavior.defaultFirstBehaviorName(isChinese: wasChinese) {
                return Behavior.defaultFirstBehaviorName(isChinese: isChinese)
            }
            let id = Behavior.ids[i]
            let oldD = Behavior.defaultName(id: id, isChinese: wasChinese)
            let newD = Behavior.defaultName(id: id, isChinese: isChinese)
            return name == oldD ? newD : name
        }
        storage.setBehaviorNames(names)
        objectWillChange.send()
    }
    
    func refresh() {
        records = storage.loadRecords()
    }
    
    func addRecord(_ record: PuffRecord) {
        // 先更新内存，保证首页点击后计数立即 +1；持久化随后完成。
        records.insert(record, at: 0)
        lastRecordedId = record.id
        storage.addRecord(record)
    }
    
    /// 小彩蛋：若本次记录后总次数刚达到某个未展示过的里程碑，返回该数字，并标记为已展示；否则返回 nil
    func checkMilestoneAfterRecord() -> Int? {
        let total = records.count
        var shown = Set(UserDefaults.standard.stringArray(forKey: kShownMilestones)?.compactMap { Int($0) } ?? [])
        for m in kMilestones where m == total && !shown.contains(m) {
            shown.insert(m)
            UserDefaults.standard.set(shown.map { String($0) }, forKey: kShownMilestones)
            return m
        }
        return nil
    }
    
    func updateRecordTags(id: UUID, typeIds: [String]) {
        storage.updateRecord(id: id, typeIds: typeIds)
        refresh()
    }
    
    func record(byId id: UUID) -> PuffRecord? {
        records.first { $0.id == id }
    }
    
    func clearLastRecordedId() {
        lastRecordedId = nil
    }
    
    func deleteRecord(id: UUID) {
        storage.deleteRecord(id: id)
        refresh()
    }
    
    func records(on date: Date) -> [PuffRecord] {
        let cal = Calendar.current
        return records.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    func count(on date: Date) -> Int {
        records(on: date).count
    }
    
    func records(from start: Date, to end: Date) -> [PuffRecord] {
        records.filter { $0.timestamp >= start && $0.timestamp <= end }
    }
    
    func hourlyCounts(for dates: [Date], behaviorId: String? = nil) -> [Int] {
        let cal = Calendar.current
        var counts = Array(repeating: 0, count: 24)
        let dayStarts = Set(dates.map { cal.startOfDay(for: $0) })
        for record in records {
            let day = cal.startOfDay(for: record.timestamp)
            guard dayStarts.contains(day) else { continue }
            if let bid = behaviorId {
                guard record.typeIds.contains(bid) else { continue }
            }
            let hour = cal.component(.hour, from: record.timestamp)
            counts[hour] += 1
        }
        return counts
    }
    
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

    /// 按「记录时的行为名称」分组统计；用户改名后历史与新记录会分开显示
    func behaviorDistribution(from start: Date, to end: Date) -> [(name: String, count: Int)] {
        let list = records(from: start, to: end)
        var dict: [String: Int] = [:]
        for rec in list {
            let name = rec.recordedBehaviorName ?? displayNameForTagId(rec.typeIds.first ?? "")
            dict[name, default: 0] += 1
        }
        return dict.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }
    
    var consecutiveRecordDays: Int {
        let cal = Calendar.current
        var d = cal.startOfDay(for: Date())
        let daysWithRecords = Set(records.map { cal.startOfDay(for: $0.timestamp) })
        var c = 0
        while c < 365 {
            if !daysWithRecords.contains(d) { break }
            c += 1
            guard let next = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = next
        }
        return c
    }
    
    func peakHour(from dates: [Date], behaviorId: String? = nil) -> Int? {
        let counts = hourlyCounts(for: dates, behaviorId: behaviorId)
        guard let maxVal = counts.max(), maxVal > 0 else { return nil }
        return counts.firstIndex(of: maxVal)
    }

    /// 周期内每日、每行为 b1～b4 的计数（统计页多行为折线用）；单次遍历内存中的 records，避免按天反复读盘
    func behaviorCountsPerDay(from start: Date, to end: Date) -> [(date: Date, counts: [String: Int])] {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        var byDay: [Date: [String: Int]] = [:]
        for rec in records {
            let t = rec.timestamp
            guard t >= start && t <= end else { continue }
            let day = cal.startOfDay(for: t)
            guard day >= startDay && day <= endDay else { continue }
            var dict = byDay[day] ?? [:]
            for id in rec.typeIds where Behavior.ids.contains(id) {
                dict[id, default: 0] += 1
            }
            byDay[day] = dict
        }
        var d = startDay
        var result: [(Date, [String: Int])] = []
        while d <= endDay {
            result.append((d, byDay[d] ?? [:]))
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        return result
    }

    var todayCount: Int {
        count(on: Date())
    }
    
    /// 用于设定页、小组件、日历详情：根据 tagId（行为 id 或旧版标签）返回显示名
    func displayNameForTagId(_ id: String) -> String {
        if let idx = Behavior.ids.firstIndex(of: id) {
            let names = storage.behaviorNames()
            if idx < names.count, !names[idx].isEmpty { return names[idx] }
            return Behavior.defaultName(id: id, isChinese: isChinese)
        }
        if let type = PuffType(rawValue: id) {
            return type.displayName(isChinese: isChinese)
        }
        if id.hasPrefix("custom:") {
            return String(id.dropFirst(7))
        }
        return id
    }

    /// 4 个行为名称（用于主页按键与设定）
    func behaviorNames() -> [String] { storage.behaviorNames() }

    func setBehaviorName(at index: Int, name: String) {
        var names = storage.behaviorNames()
        guard index >= 0, index < names.count else { return }
        names[index] = name.trimmingCharacters(in: .whitespacesAndNewlines)
        storage.setBehaviorNames(names)
        objectWillChange.send()
        refresh()
    }

    /// 添加一个行为槽位（最多 4 个）
    func addBehaviorSlot() {
        var names = storage.behaviorNames()
        guard names.count < Behavior.maxCount else { return }
        let isChinese = isChinese
        names.append(Behavior.defaultName(id: Behavior.ids[names.count], isChinese: isChinese))
        storage.setBehaviorNames(names)
        objectWillChange.send()
        refresh()
    }

    /// 移除最后一个行为槽位（至少保留 1 个）
    func removeLastBehaviorSlot() {
        var names = storage.behaviorNames()
        guard names.count > 1 else { return }
        names.removeLast()
        storage.setBehaviorNames(names)
        objectWillChange.send()
        refresh()
    }

    /// 移除指定索引的行为槽位（索引 0 不可删，仅能改名）
    func removeBehaviorSlot(at index: Int) {
        var names = storage.behaviorNames()
        guard index > 0, index < names.count else { return }
        names.remove(at: index)
        storage.setBehaviorNames(names)
        objectWillChange.send()
        refresh()
    }

    /// 所有可选标签（当前 1～4 个行为），供小组件常用标签设定用
    func allAvailableTagOptions() -> [(id: String, name: String)] {
        let names = storage.behaviorNames()
        return (0..<names.count).map { (Behavior.ids[$0], names[$0]) }
    }
}
