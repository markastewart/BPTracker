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
    var timestamp: Date
    var systalic: String
    var distalic: String
    
    init() {
        self.timestamp = Date()
        self.systalic = ""
        self.distalic = ""
    }
}
