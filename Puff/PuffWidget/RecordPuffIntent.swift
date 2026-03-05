//
//  RecordPuffIntent.swift
//  PuffWidget
//
//  iOS 17+：App Intent 实现小组件点击 +1 不打开主应用。
//  使用 Xcode 15+ 时，在 PuffWidget target 的 Link Binary With Libraries 中添加
//  AppIntents.framework（Optional），即可在 iOS 17 设备上点击小组件仅 +1 不跳转 App。
//

import Foundation
import WidgetKit

#if canImport(AppIntents)
import AppIntents
#endif

private let kWidgetRecordsKey = "puff_records"
private let kWidgetSuiteName = "group.com.puff.app"

private struct WidgetRecordItem: Codable {
    let id: UUID
    let timestamp: Date
    var typeIds: [String]
}

/// 通过 App Group 写入一条记录（主应用与小组件共享）
func widgetAddOneRecord() {
    let suite = UserDefaults(suiteName: kWidgetSuiteName) ?? UserDefaults.standard
    var list: [WidgetRecordItem] = []
    if let data = suite.data(forKey: kWidgetRecordsKey),
       let decoded = try? JSONDecoder().decode([WidgetRecordItem].self, from: data) {
        list = decoded
    }
    list.insert(WidgetRecordItem(id: UUID(), timestamp: Date(), typeIds: []), at: 0)
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

#if canImport(AppIntents)
@available(iOS 17.0, *)
struct RecordPuffIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Puff"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        widgetAddOneRecord()
        return .result()
    }
}

@available(iOS 17.0, *)
struct AddTagToLastRecordIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Tag to Last"
    static var openAppWhenRun: Bool = false
    var tagId: String
    init(tagId: String) { self.tagId = tagId }

    func perform() async throws -> some IntentResult {
        widgetAddTagToLastRecord(tagId: tagId)
        return .result()
    }
}
#endif
