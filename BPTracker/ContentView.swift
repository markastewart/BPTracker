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
                           Text("\(bpRecord.distalic)/\(bpRecord.systalic)").font(.subheadline)
                       }
                   }
                   .onDelete(perform: deleteItems)
               }
                .toolbar {
                    ToolbarItem {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Add", action: { showAddView = true })
                                                .fullScreenCover(isPresented: $showAddView, content: { DetailView() })
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

    private func addItem() {
        withAnimation {
            let newItem = BPDetails()
            newItem.distalic = Int.random(in: 98..<140)
            newItem.systalic = Int.random(in: 65..<120)
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(bpDetailResults[index])
            }
        }
    }
}

struct DetailView: View {
    var body: some View {
        Text("Hello DetailView")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BPDetails.self, inMemory: true)
}
