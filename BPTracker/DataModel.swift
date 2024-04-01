//
//  DataModel.swift
//  BPTracker
//
//  Created by Mark A Stewart on 3/25/24.
//

import Foundation
import SwiftData

@Model
final class BPDetails {
    var id: UUID
    var timestamp: Date
    var systalic: Int
    var distalic: Int
    var totalmmHg: Int
    
    init() {
        self.id = UUID()
        self.timestamp = Date()
        self.systalic = 0
        self.distalic = 0
        self.totalmmHg = 0
    }
}
