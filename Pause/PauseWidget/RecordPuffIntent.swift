//
//  RecordPuffIntent.swift
//  PauseWidget
//
//  iOS 17+: Button(intent: RecordPuffIntent()) 点击 +1 不打开 App。
//  若需 AddTagToLastRecordIntent，请确保 Widget 目标可链接 AppIntents（Optional）。
//

import WidgetKit

private let kWidgetRecordsKey = "pause_records"
private let kWidgetSuiteName = "group.com.pause.app"
private let kBehaviorNamesKey = "Pause.behaviorNames"
private let kAppLanguageIsChinese = "Pause.appLanguageIsChinese"

/// 与主应用 PuffRecord 解码兼容（含 recordedBehaviorName）
private struct WidgetRecordItem: Codable {
    let id: UUID
    let timestamp: Date
    var typeIds: [String]
    var recordedBehaviorName: String?
}

private let kBehaviorIds = ["b1", "b2", "b3", "b4"]

private func widgetBehaviorName(for behaviorId: String) -> String {
    let suite = UserDefaults(suiteName: kWidgetSuiteName) ?? UserDefaults.standard
    let names = suite.stringArray(forKey: kBehaviorNamesKey) ?? []
    let isChinese = suite.object(forKey: kAppLanguageIsChinese) == nil ? true : suite.bool(forKey: kAppLanguageIsChinese)
    guard let idx = kBehaviorIds.firstIndex(of: behaviorId), idx < names.count, !names[idx].isEmpty else {
        return isChinese ? "咬指甲" : "Nail biting"
    }
    return names[idx]
}

/// 通过 App Group 写入一条记录（主应用与小组件共享）；指定行为 id
func widgetAddOneRecord(behaviorId: String = "b1") {
    let suite = UserDefaults(suiteName: kWidgetSuiteName) ?? UserDefaults.standard
    var list: [WidgetRecordItem] = []
    if let data = suite.data(forKey: kWidgetRecordsKey),
       let decoded = try? JSONDecoder().decode([WidgetRecordItem].self, from: data) {
        list = decoded
    }
    let name = widgetBehaviorName(for: behaviorId)
    list.insert(WidgetRecordItem(id: UUID(), timestamp: Date(), typeIds: [behaviorId], recordedBehaviorName: name), at: 0)
    let data = (try? JSONEncoder().encode(list)) ?? Data()
    suite.set(data, forKey: kWidgetRecordsKey)
    WidgetCenter.shared.reloadAllTimelines()
}

/// 给最后一条记录追加标签（可多选，重复点同一标签只算一次）
func widgetAddTagToLastRecord(tagId: String) {
    let suite = UserDefaults(suiteName: kWidgetSuiteName) ?? UserDefaults.standard
    var list: [WidgetRecordItem] = []
    if let data = suite.data(forKey: kWidgetRecordsKey),
       let decoded = try? JSONDecoder().decode([WidgetRecordItem].self, from: data) {
        list = decoded
    }
    guard !list.isEmpty else { WidgetCenter.shared.reloadAllTimelines(); return }
    var first = list[0]
    if !first.typeIds.contains(tagId) {
        first.typeIds.append(tagId)
        list[0] = first
        let data = (try? JSONEncoder().encode(list)) ?? Data()
        suite.set(data, forKey: kWidgetRecordsKey)
    }
    WidgetCenter.shared.reloadAllTimelines()
}

// 小组件不链接 AppIntents 框架，点击按键通过 Link 打开 App 并记录（pause://record?tag=b1 等）
