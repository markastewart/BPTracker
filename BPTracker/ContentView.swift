//
//  ContentView.swift
//  BPTracker
//
//  Created by Mark A Stewart on 3/25/24.
//

import SwiftUI
import SwiftData

public extension View {
    @MainActor
    func snapshot(scale: CGFloat? = nil) -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = scale ?? UIScreen.main.scale
        return renderer.uiImage
    }
}

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
                    newItem.timestamp = bpTimeStamp
                    newItem.systalic = systalicInput+90
                    newItem.distalic = diastalicInput+70
                    newItem.totalmmHg = newItem.systalic + newItem.distalic
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
    @Query(sort: \BPDetails.timestamp) var bpDetailResults: [BPDetails]
    @Binding var showResults: Bool
    @State var startDate = Date()
    @State var endDate = Date()
    @State var showReport = false
    
    var body: some View {
        HStack {
            Spacer()
            Text("Select Blood Pressure Results").font(.headline).padding(.vertical, 35)
                .onAppear() {
                    if let firstBPRec = bpDetailResults.first {
                        startDate = firstBPRec.timestamp
                    }
                    if let lastBPRec = bpDetailResults.last {
                        endDate = lastBPRec.timestamp
                    }
                }
            Spacer()
        }
        
        VStack {
            HStack {
                DatePicker("Start Date", selection: $startDate, displayedComponents:.date)
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                DatePicker("End Date", selection: $endDate, displayedComponents:.date)
                Spacer()
            }.padding(.horizontal, 20)
            
            HStack {
                Button("Show Data") {
                    showReport = true
                }
                .fullScreenCover(isPresented: $showReport, content: { ShowReport(showReport: $showReport, startDate: $startDate, endDate: $endDate) })
                
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
    @Query(sort: \BPDetails.timestamp) var bpDetailResults: [BPDetails]
    @Binding var showReport: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var body: some View {
        ShowReportTitle(startDate: $startDate, endDate:$endDate)
        
        let recordsPerPage = 20
        let recordCount = bpDetailResults.count
        let pageCount = (Double (recordCount) / Double (recordsPerPage)).rounded(.up)
        
        ScrollView {
            ForEach(0..<Int(pageCount), id: \.self) { index in
                ShowReportSegment(startDate: $startDate, endDate:$endDate, segment:index, records: formatRecords(records: bpDetailResults))
            }
        }
        
        HStack {
            Button("Print") {
                let page1View = VStack {
                    ShowReportTitle(startDate: $startDate, endDate:$endDate)
                    ShowReportSegment(startDate: $startDate, endDate:$endDate, segment:0, records: formatRecords(records: bpDetailResults))
                    ShowReportFooter(currentPage: 1, totalPages: 2)
                }.font(.subheadline)
                let page1Image = page1View.snapshot()!
                let page2View = VStack {
                    ShowReportTitle(startDate: $startDate, endDate:$endDate)
                    ShowReportSegment(startDate: $startDate, endDate:$endDate, segment:1, records: formatRecords(records: bpDetailResults))
                    ShowReportFooter(currentPage: 2, totalPages: 2)
                }.font(.subheadline)
                let page2Image = page2View.snapshot()!
                
                DispatchQueue.main.async {
                    let info = UIPrintInfo(dictionary: nil)
                    info.outputType = .general
                    info.jobName = "Standard Printer Job"
                    info.duplex = .shortEdge
                    info.orientation = .portrait
                    let printView = UIPrintInteractionController.shared
                    printView.printingItems = [page1Image, page2Image]
                    printView.printInfo = info
                    printView.present(animated: true)
                }
            }
            Spacer()
            Button("Cancel") {
                showReport = false
            }
        }.padding(.horizontal, 50).padding(.vertical,20)
            .font(.subheadline)
    }
    
    func formatRecords(records: [BPDetails]) -> [String] {
        return records.map { record in
            return "\(record.timestamp.formatted(date: .numeric, time: .shortened)): \(record.systalic)/\(record.distalic) mmHg"
        }
    }
}
struct ShowReportTitle: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var body: some View {
        VStack {
            Text("Blood Pressure Results  -  \(Date().formatted(date: .numeric, time: .omitted))").fontWeight(.bold)
            Text("")
            Text("Date range: (\(startDate.formatted(date: .numeric, time: .omitted))-\(endDate.formatted(date: .numeric, time: .omitted)))").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            Text("")
        }.font(.system(size: 14))
    }
}

struct ShowReportSegment: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    var segment : Int
    var records : [String]
    
    var body: some View {
        let recordsPerPage = 20
        let recordCount = records.count
        let pageCount = (Double (recordCount) / Double (recordsPerPage)).rounded(.up)
        
        let recordsInSegment = Int(pageCount-1) == segment ? (records.count - (segment * recordsPerPage)) : recordsPerPage
        
        ForEach (0..<recordsInSegment, id: \.self) { index in
            let arrayIndex = index+(segment*recordsPerPage)
            Text("\(records[arrayIndex])")
                .font(.system(size: 14))
            Divider()
        }
    }
}

struct ShowReportFooter: View {
    var currentPage: Int
    var totalPages: Int
    
    var body: some View {
        Text("")
        Text("Page \(currentPage) of \(totalPages)").font(.subheadline)
    }
}
