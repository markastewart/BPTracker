//
//  EnterInputView.swift
//  BPTracker
//
//  Created by Mark A Stewart on 4/5/24.
//

import SwiftUI

enum MMHgBase:  Int {
    case systolicBase = 90
    case distolicBase = 60
}

enum MMHgLimit:  Int {
    case systolicLimit = 166
    case distolicLimit = 121
}

struct EnterInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showEnterBPInput: Bool
    @State var bpTimeStamp = Date()
    @State var systolicInput = MMHgBase.systolicBase.rawValue + 20
    @State var distolicInput = MMHgBase.distolicBase.rawValue + 10
    
    var body: some View {
        HStack {
            Spacer()
            Text("Blood Pressure Input").font(.headline).padding(.vertical, 35)
            Spacer()
        }
        
        VStack {
            HStack {
                DatePicker("Date of Reading", selection: $bpTimeStamp, displayedComponents:.date)
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                DatePicker("Time of Reading", selection: $bpTimeStamp, displayedComponents:.hourAndMinute)
                    .onAppear{
                        UIDatePicker.appearance().minuteInterval = 15
                    }
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                Text("Systolic:")
                let systolicBase = MMHgBase.systolicBase.rawValue
                let systolicLimit = MMHgLimit.systolicLimit.rawValue
                Picker("", selection: $systolicInput) {
                    ForEach(systolicBase..<systolicLimit, id: \.self) {
                        Text("\($0)")
                    }
                }
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                Text("Diastolic:")
                let distolicBase = MMHgBase.distolicBase.rawValue
                let distolicLimit = MMHgLimit.distolicLimit.rawValue
                Picker("", selection: $distolicInput) {
                    ForEach(distolicBase..<distolicLimit, id: \.self) {
                        Text("\($0)")
                    }
                }
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                Button("Save") {
                    BPDetails().saveBPDetails(context: modelContext, bpTimeStamp: bpTimeStamp, systolic: systolicInput, diastolic: distolicInput)
                    showEnterBPInput = false
                }
                Spacer()
                Button("Cancel") {
                    showEnterBPInput = false
                }
            }.padding(.horizontal, 50).padding(.vertical,20)
        }
        .font(.subheadline)
    }
}

//#Preview {
//    EnterInputView()
//}
