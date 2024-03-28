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
    @Query private var bpDetailResults: [BPDetails]
    let showRecordLimit = 10
    let grid2Member = [GridItem(.fixed(175), alignment: .leading), GridItem(.fixed(75), alignment: .leading)]
    @State var showAddView = false

    var body: some View {
        VStack {
            HStack {
                Text("BP Tracker").foregroundStyle(.black).fontWeight(.bold)
                Image(systemName: "heart.fill").foregroundStyle(.red)
            }
            
           NavigationSplitView {
               List {
                   if bpDetailResults.count == 0 {
                       Text("No Readings")
                   } else {
                       if bpDetailResults.count < showRecordLimit {
                           Text("Last \(bpDetailResults.count) Readings")
                       }
                       else {
                           Text("Last \(showRecordLimit) Readings")
                       }
                   }
                   ForEach(bpDetailResults.reversed().prefix(showRecordLimit)) { bpRecord in
                       LazyVGrid(columns: grid2Member) {
                           Text(bpRecord.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard)).font(.subheadline)
                           Text("\(bpRecord.systalic)/\(bpRecord.distalic)").font(.subheadline)
                       }
                   }
                   .onDelete(perform: deleteItems)
               }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showAddView = true }) {
                            Label("Add item", systemImage: "plus")
                        }
                        .fullScreenCover(isPresented: $showAddView, content: { EnterBPResult(showAddView: $showAddView) })
                    }
                    
                    ToolbarItem {
                        EditButton()
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Show Results") {
                            //
                        }
                    }
                }
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

struct EnterBPResult: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showAddView: Bool
    @State var bpTimeStamp = Date()
    @State var systalicInput = 20
    @State var diastalicInput = 10
    var newItem = BPDetails()
    
    var body: some View {
        HStack {
            Spacer()
            Text("Blood Pressure Input").font(.headline).padding(.bottom, 50)
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
                    showAddView = false
                }
                Spacer()
                Button("Cancel") {
                    showAddView = false
                }
            }.padding(100)
        }
        .font(.subheadline)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BPDetails.self, inMemory: true)
}
