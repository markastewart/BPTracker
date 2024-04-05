//
//  EnterInputView.swift
//  BPTracker
//
//  Created by Mark A Stewart on 4/5/24.
//

import SwiftUI

struct EnterInputView: View {
        @Environment(\.modelContext) private var modelContext
        @Binding var showEnterBPInput: Bool
        @State var bpTimeStamp = Date()
        @State var systalicInput = 20
        @State var diastalicInput = 10
        
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
                    Picker("", selection: $systalicInput) {
                        ForEach(90..<166) {
                            Text("\($0)")
                        }
                    }
                    Spacer()
                }.padding(.horizontal, 20)
                
                HStack {
                    Text("Diastolic:")
                    Picker("", selection: $diastalicInput) {
                        ForEach(60..<121) {
                            Text("\($0)")
                        }
                    }
                    Spacer()
                }.padding(.horizontal, 20)
                
                HStack {
                    Button("Save") {
                        BPDetails().saveBPDetails(context: modelContext, bpTimeStamp: bpTimeStamp, systolic: systalicInput, diastolic: diastalicInput)
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
