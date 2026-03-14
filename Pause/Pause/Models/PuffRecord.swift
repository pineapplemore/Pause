//
//  PuffRecord.swift
//  Pause
//
//  单条行为记录；typeIds 存行为槽位 id（b1~b4），recordedBehaviorName 为记录时的行为名称（用于统计分开显示）
//

import Foundation

struct PuffRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    var typeIds: [String]  // 行为槽位 id：b1, b2, b3, b4
    /// 记录时的行为显示名；若存在则统计按此名分组，改名后历史与新记录分开显示
    var recordedBehaviorName: String?
    
    init(id: UUID = UUID(), timestamp: Date = Date(), typeIds: [String] = [], recordedBehaviorName: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.typeIds = typeIds
        self.recordedBehaviorName = recordedBehaviorName
    }
    
    var types: [PuffType] {
        typeIds.compactMap { PuffType(rawValue: $0) }
    }
}
