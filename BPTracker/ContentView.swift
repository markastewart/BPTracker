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

    var body: some View {
        VStack {
            HStack {
                Text("BP Tracker").foregroundStyle(.black).fontWeight(.bold)
                Image(systemName: "heart.fill").foregroundStyle(.red)
            }
            
           NavigationSplitView {
               List {
                   Text("Last \(showRecordLimit) Readings")
                   ForEach(bpDetailResults.reversed().prefix(showRecordLimit)) { bpRecord in
                       Text(bpRecord.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard)).font(.subheadline)
//                       NavigationLink {
//                           Text("Item at \(bpRecord.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
//                       } label: {
//                           Text(bpRecord.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard)).font(.subheadline)
//                       }
                   }
                   .onDelete(perform: deleteItems)
               }
                .toolbar {
                    ToolbarItem {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
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

#Preview {
    ContentView()
        .modelContainer(for: BPDetails.self, inMemory: true)
}
