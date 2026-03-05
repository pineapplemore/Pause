//
//  RecordPuffIntent.swift
//  PuffWidget
//
//  小组件点击「＋1」：通过 puff://record 打开主应用并自动记录一次。
//  若使用 Xcode 15+（iOS 17 SDK），可改为 App Intents 实现不打开应用即记录。
//

import Foundation

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
}
