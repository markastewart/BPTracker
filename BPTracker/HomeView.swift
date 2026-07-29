//
//  HomeView.swift
//  BPTracker
//
//  Created by Mark A Stewart on 4/5/24.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BPDetails.timestamp, order: .reverse) var bpDetailResults: [BPDetails]
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
                        .onAppear {
                            BPDetails().loadRecs(context: modelContext)
                        }
                } else {
                    Text("Most Recent Readings").fontWeight(.bold)
                }

                ScrollViewReader { scrollView in
                    List {
                        ForEach(bpDetailResults) { bpRecord in
                            LazyVGrid(columns: grid2Member) {
                                Text(bpRecord.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                                Text("\(bpRecord.systalic)/\(bpRecord.distalic) (\(bpRecord.pulse))")
                            }
                            .id(bpRecord.id)
                            .font(.subheadline)
                        }
                        .onDelete(perform: deleteItems)
                        .onChange(of: bpDetailResults.count) {
                            let lastRecord = bpDetailResults.count - 1
                            scrollView.scrollTo(bpDetailResults[lastRecord].id)
                        }
                        .onAppear(perform: {
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
                    }

                    ToolbarItem {
                        Button(action: { isEditing.toggle() }) {
                            Image(systemName: isEditing ? "pencil.circle" : "pencil")
                        }
                    }

                    ToolbarItem {
                        Button(action: { showResults = true }) {
                            Label("Results", systemImage: "doc.text")
                        }
                    }
                }
                .sheet(isPresented: $showEnterBPInput) {
                    EnterInputView(showEnterBPInput: $showEnterBPInput)
                }
                .sheet(isPresented: $showResults) {
                    ShowResults(showResults: $showResults)
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

#Preview {
    HomeView()
}
