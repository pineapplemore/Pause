//
//  PuffRecord.swift
//  Puff
//
//  单条放屁记录
//

import Foundation

struct PuffRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    var typeIds: [String]  // PuffType.rawValue
    
    init(id: UUID = UUID(), timestamp: Date = Date(), typeIds: [String] = []) {
        self.id = id
        self.timestamp = timestamp
        self.typeIds = typeIds
    }
    
    var types: [PuffType] {
        typeIds.compactMap { PuffType(rawValue: $0) }
    }
}
