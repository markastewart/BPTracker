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
//    var systalic: Int
//    var distalic: Int
    
    init() {
        self.timestamp = Date()
//        self.systalic = 0
//        self.distalic = 0
    }
}
