//
//  ContentView.swift
//  BPTracker
//
//  Created by Mark A Stewart on 3/25/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BPDetails.timestamp) var bpDetailResults: [BPDetails]
    let grid2Member = [GridItem(.fixed(175), alignment: .leading), GridItem(.fixed(75), alignment: .leading)]
    @State var showEnterBPInput = false
    @State var showResults = false
    @State var isEditing = false
    
    var body: some View {
        VStack {
            HStack {
                Text("BP Tracker").foregroundStyle(.black).fontWeight(.bold)
                Image(systemName: "heart.fill").foregroundStyle(.red)
            }
            
            NavigationSplitView {
                if bpDetailResults.count == 0 {
                    Text("No Readings").fontWeight(.bold)
                } else {
                    Text("Most Recent Readings").fontWeight(.bold)
                }
                
                ScrollViewReader { scrollView in
                    List {
                        ForEach(bpDetailResults) { bpRecord in
                            LazyVGrid(columns: grid2Member) {
                                Text(bpRecord.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened)).font(.subheadline)
                                Text("\(bpRecord.systalic)/\(bpRecord.distalic)").font(.subheadline)
                            }.id(bpRecord.id)
                        }
                        .onDelete(perform: deleteItems)
                        .onChange (of: bpDetailResults.count) {
                            let lastRecord = bpDetailResults.count - 1
                            scrollView.scrollTo(bpDetailResults[lastRecord].id)
                        }
                        .onAppear (perform: {
                            DispatchQueue.main.async() {
                                scrollView.scrollTo(bpDetailResults[bpDetailResults.count - 1].id)
                            }
                        })
                    }
                    .frame(height: 530)
                }
                .toolbar {
                    ToolbarItem {
                        Button(action: { showEnterBPInput = true }) {
                            Label("Add item", systemImage: "plus")
                        }
                        .popover(isPresented: $showEnterBPInput, content: {
                            EnterBPInput(showEnterBPInput: $showEnterBPInput)
                                .presentationCompactAdaptation(.popover)
                        })
                    }
                    
                    ToolbarItem {
                        Button(action: { isEditing.toggle() }) {
                            Image(systemName: isEditing ? "pencil.circle" : "pencil")
                        }
                    }
                    
                    ToolbarItem {
                        Button(action: { showResults = true}) {
                            Label("", systemImage: "doc.text")
                        }
                        .popover(isPresented: $showResults, content: {
                            ShowResults(showResults: $showResults)
                                .presentationCompactAdaptation(.popover)
                        })
                    }
                }
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            } detail: {
                Text("Select an item")
            }
        }
        .background(.gray.opacity(0.50))
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(bpDetailResults[index])
            }
        }
    }
}

struct EnterBPInput: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showEnterBPInput: Bool
    @State var bpTimeStamp = Date()
    @State var systalicInput = 20
    @State var diastalicInput = 10
    var newItem = BPDetails()
    
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
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                Text("Systalic:")
                Picker("", selection: $systalicInput) {
                    ForEach(90..<151) {
                        Text("\($0)")
                    }
                }
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                Text("Diastalic:")
                Picker("", selection: $diastalicInput) {
                    ForEach(70..<121) {
                        Text("\($0)")
                    }
                }
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                Button("Save") {
                    newItem.timestamp = bpTimeStamp
                    newItem.systalic = String(systalicInput+90)
                    newItem.distalic = String(diastalicInput+70)
                    modelContext.insert(newItem)
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


struct ShowResults: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BPDetails.timestamp) var bpDetailResults: [BPDetails]
    @Binding var showResults: Bool
    @State var bpStartTime = Date()
    @State var bpEndTime = Date()
    @State var showReport = false
    
    var body: some View {
        HStack {
            Spacer()
            Text("Select Blood Pressure Results").font(.headline).padding(.vertical, 35)
                .onAppear() {
                    if let firstBPRec = bpDetailResults.first {
                        bpStartTime = firstBPRec.timestamp
                    }
                    if let lastBPRec = bpDetailResults.last {
                        bpEndTime = lastBPRec.timestamp
                    }
                }
            Spacer()
        }
        
        VStack {
            HStack {
                DatePicker("Start Date", selection: $bpStartTime, displayedComponents:.date)
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                DatePicker("End Date", selection: $bpEndTime, displayedComponents:.date)
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                Button("Show Data") {
                    showReport = true
                }
                .fullScreenCover(isPresented: $showReport, content: { ShowReport(showReport: $showReport) })
                
                Spacer()
                Button("Cancel") {
                    showResults = false
                }
            }.padding(.horizontal, 50).padding(.vertical,20)
        }
        .font(.subheadline)
    }
}

struct ShowReport: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showReport: Bool
    @State var bpStartTime = Date()
    @State var bpEndTime = Date()
    
    var body: some View {
        HStack {
            Spacer()
            Text("Blood Pressure Results").font(.headline).padding(.vertical, 35)
            Spacer()
        }
        
        VStack {
            HStack {
                Button("Cancel") {
                    showReport = false
                }
            }.padding(.horizontal, 50).padding(.vertical,20)
        }
        .font(.subheadline)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: BPDetails.self, inMemory: true)
}
