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
    
    func saveBPDetails(context:ModelContext, bpTimeStamp:Date, systolic:Int, diastolic:Int) {
        let newItem = BPDetails()
        newItem.timestamp = bpTimeStamp
        newItem.systalic = systolic
        newItem.distalic = diastolic
        newItem.totalmmHg = newItem.systalic + newItem.distalic
        context.insert(newItem)
        try! context.save()
    }
    
    func loadRecs(context: ModelContext) {
        var dateComponents = DateComponents()
        
        for _ in 0...60 {
            dateComponents.year = 2024
            dateComponents.month = Int.random(in: 3..<5)
            dateComponents.day = Int.random(in: 1..<30)
            dateComponents.hour = Int.random(in: 1..<24)
            dateComponents.minute = 15
        }
    }
}
