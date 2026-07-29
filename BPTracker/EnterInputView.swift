//
//  EnterInputView.swift
//  BPTracker
//
//  Created by Mark A Stewart on 4/5/24.
//

import SwiftUI

enum MMHgBase: Int {
    case systolicBase = 90
    case distolicBase = 60
}

enum MMHgLimit: Int {
    case systolicLimit = 166
    case distolicLimit = 121
}

struct EnterInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showEnterBPInput: Bool
    @State var bpTimeStamp = Date()
    @State var systolicInput = MMHgBase.systolicBase.rawValue + 20
    @State var distolicInput = MMHgBase.distolicBase.rawValue + 10
    @State var pulseInput = 72
    
    private var systolicRange: ClosedRange<Int> {
        MMHgBase.systolicBase.rawValue...(MMHgLimit.systolicLimit.rawValue - 1)
    }
    private var distolicRange: ClosedRange<Int> {
        MMHgBase.distolicBase.rawValue...(MMHgLimit.distolicLimit.rawValue - 1)
    }
    private let pulseRange = 25...300
    
    private var isSystolicValid: Bool { systolicRange.contains(systolicInput) }
    private var isDistolicValid: Bool { distolicRange.contains(distolicInput) }
    private var isPulseValid: Bool { pulseRange.contains(pulseInput) }
    private var canSave: Bool { isSystolicValid && isDistolicValid && isPulseValid }
    
    var body: some View {
        HStack {
            Spacer()
            Text("Blood Pressure Input").font(.headline).padding(.vertical, 35)
            Spacer()
        }
        
        VStack {
            HStack {
                DatePicker("Date of Reading", selection: $bpTimeStamp, displayedComponents: .date)
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                DatePicker("Time of Reading", selection: $bpTimeStamp, displayedComponents: .hourAndMinute)
                Spacer()
            }.padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Systolic:")
                    TextField("Systolic", value: $systolicInput, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .foregroundColor(isSystolicValid ? .primary : .red)
                    Spacer()
                }
                if !isSystolicValid {
                    Text("Enter a value between \(systolicRange.lowerBound) and \(systolicRange.upperBound)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }.padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Diastolic:")
                    TextField("Diastolic", value: $distolicInput, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .foregroundColor(isDistolicValid ? .primary : .red)
                    Spacer()
                }
                if !isDistolicValid {
                    Text("Enter a value between \(distolicRange.lowerBound) and \(distolicRange.upperBound)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }.padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Pulse:")
                    TextField("Pulse", value: $pulseInput, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .foregroundColor(isPulseValid ? .primary : .red)
                    Spacer()
                }
                if !isPulseValid {
                    Text("Enter a value between \(pulseRange.lowerBound) and \(pulseRange.upperBound)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }.padding(.horizontal, 20)
            
            HStack {
                Button("Save") {
                    BPDetails().saveBPDetails(context: modelContext, bpTimeStamp: bpTimeStamp, systolic: systolicInput, diastolic: distolicInput, pulse: pulseInput)
                    showEnterBPInput = false
                }
                .disabled(!canSave)
                Spacer()
                Button("Cancel") {
                    showEnterBPInput = false
                }
            }.padding(.horizontal, 50).padding(.vertical, 20)
        }
        .font(.subheadline)
    }
}
