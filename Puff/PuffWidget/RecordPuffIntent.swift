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

/// 通过 App Group 写入一条记录（主应用与小组件共享）
func widgetAddOneRecord() {
    let suite = UserDefaults(suiteName: "group.com.puff.app") ?? UserDefaults.standard
    let key = "puff_records"
    struct Item: Codable { let id: UUID; let timestamp: Date; var typeIds: [String] }
    var list: [Item] = []
    if let data = suite.data(forKey: key),
       let decoded = try? JSONDecoder().decode([Item].self, from: data) {
        list = decoded
    }
    list.insert(Item(id: UUID(), timestamp: Date(), typeIds: []), at: 0)
    let data = (try? JSONEncoder().encode(list)) ?? Data()
    suite.set(data, forKey: key)
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
#endif
