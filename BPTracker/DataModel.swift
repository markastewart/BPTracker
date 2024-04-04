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
        newItem.systalic = systolic+90
        newItem.distalic = diastolic+70
        newItem.totalmmHg = newItem.systalic + newItem.distalic
        context.insert(newItem)
    }
    
    func loadRecs(context: ModelContext) {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        
        for _ in 0...40 {
            dateComponents.year = 2024
            dateComponents.month = Int.random(in: 3..<5)
            dateComponents.day = Int.random(in: 1..<30)
            dateComponents.hour = Int.random(in: 1..<24)
            dateComponents.minute = 15
            let bpTimeStamp = calendar.date(from: dateComponents)
            let systalic = Int.random(in: 0..<60)
            let distalic = Int.random(in: 0..<50)
            saveBPDetails(context:context, bpTimeStamp:bpTimeStamp!, systolic:systalic, diastolic:distalic)
        }
    }
}
