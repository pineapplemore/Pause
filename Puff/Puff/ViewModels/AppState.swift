//
//  AppState.swift
//  Puff
//

import SwiftUI

private let kHasLaunchedBefore = "Puff.hasLaunchedBefore"
private let kLanguageIsChinese = "Puff.languageIsChinese"
private let kCustomTagNames = "Puff.customTagNames"
private let kDeletedDefaultTagIds = "Puff.deletedDefaultTagIds"
private let kShownMilestones = "Puff.shownMilestones"

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
    /// 当前是否为中文（首次启动按地区：中国区→中文，其他→英文；之后按用户切换）
    @Published var isChinese: Bool {
        didSet {
            UserDefaults.standard.set(isChinese, forKey: kLanguageIsChinese)
            storage.setAppLanguageIsChinese(isChinese)
        }
    }
    private let storage = StorageService.shared
    
    init() {
        self.customTagNames = UserDefaults.standard.stringArray(forKey: kCustomTagNames) ?? []
        let deleted = UserDefaults.standard.stringArray(forKey: kDeletedDefaultTagIds) ?? []
        self.deletedDefaultTagIds = Set(deleted)
        if UserDefaults.standard.bool(forKey: kHasLaunchedBefore) {
            self.isChinese = UserDefaults.standard.object(forKey: kLanguageIsChinese) as? Bool ?? true
        } else {
            UserDefaults.standard.set(true, forKey: kHasLaunchedBefore)
            let region = Locale.current.regionCode ?? ""
            self.isChinese = (region == "CN" || region == "HK" || region == "MO" || region == "TW")
            UserDefaults.standard.set(self.isChinese, forKey: kLanguageIsChinese)
        }
        storage.setAppLanguageIsChinese(self.isChinese)
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
        isChinese.toggle()
    }
    
    func refresh() {
        records = storage.loadRecords()
    }
    
    func addRecord(_ record: PuffRecord) {
        storage.addRecord(record)
        lastRecordedId = record.id
        refresh()
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
        storage.record(byId: id)
    }
    
    func clearLastRecordedId() {
        lastRecordedId = nil
    }
    
    func deleteRecord(id: UUID) {
        storage.deleteRecord(id: id)
        refresh()
    }
    
    func records(on date: Date) -> [PuffRecord] {
        storage.records(on: date)
    }
    
    func count(on date: Date) -> Int {
        storage.count(on: date)
    }
    
    func records(from start: Date, to end: Date) -> [PuffRecord] {
        storage.records(from: start, to: end)
    }
    
    func hourlyCounts(for dates: [Date]) -> [Int] {
        storage.hourlyCounts(for: dates)
    }
    
    func tagDistribution(from start: Date, to end: Date) -> [(String, Int)] {
        storage.tagDistribution(from: start, to: end)
    }
    
    var consecutiveRecordDays: Int {
        storage.consecutiveRecordDays()
    }
    
    func peakHour(from dates: [Date]) -> Int? {
        storage.peakHour(from: dates)
    }
    
    var todayCount: Int {
        count(on: Date())
    }
    
    /// 用于设定页、小组件：根据 tagId 返回显示名
    func displayNameForTagId(_ id: String) -> String {
        if let type = PuffType(rawValue: id) {
            return type.displayName(isChinese: isChinese)
        }
        if id.hasPrefix("custom:") {
            return String(id.dropFirst(7))
        }
        return id
    }
    
    /// 所有可选标签（未从列表移除的默认 + 自定义），供小组件常用标签设定用
    func allAvailableTagOptions() -> [(id: String, name: String)] {
        let defaultOpts = PuffType.allCases
            .filter { !deletedDefaultTagIds.contains($0.rawValue) }
            .map { ($0.rawValue, $0.displayName(isChinese: isChinese)) }
        let customOpts = customTagNames.map { ("custom:\($0)", $0) }
        return defaultOpts + customOpts
    }
}
