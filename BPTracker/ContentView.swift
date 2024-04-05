//
//  ContentView.swift
//  BPTracker
//
//  Created by Mark A Stewart on 3/25/24.
//

import SwiftUI
import SwiftData
import TPPDF
import PDFKit

public extension View {
    @MainActor
    func snapshotForPrint(scale: CGFloat? = nil) -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 1.0
        
        guard let jpegData = renderer.uiImage?.jpegData(compressionQuality: 0.1),
              let dp = CGDataProvider(data: jpegData as CFData),
              let cgImage = CGImage(jpegDataProviderSource: dp, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else {
            exit(1)
        }
        return UIImage(cgImage: cgImage)
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
//                        .onAppear {
//                            BPDetails().loadRecs(context: modelContext)
//                        }
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
    @Query(sort: \BPDetails.totalmmHg) var mmHgSorted: [BPDetails]
    @Binding var showReport: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var body: some View {
        let url = render()
        PDFKitView(url:  url)
        
        HStack {
            Button {
                render()
            } label: {
                Text("Print")
                Image(systemName: "printer")
            }
            .buttonStyle(BorderedButtonStyle())
            
            Spacer()
            Button("Cancel") {
                showReport = false
            }
        }.padding(.horizontal, 50).padding(.vertical,20)
            .font(.subheadline)
    }
    
    @MainActor func render() -> URL {
        let page1Content = AnyView (VStack {
            ShowReportTitle(startDate: $startDate, endDate:$endDate, currentPage: 1, totalPages: 3)
            ShowReportSegment(startDate: $startDate, endDate:$endDate, segment:0, records: formatRecords(records: bpDetailResults))
        })
        
        let page2Content = AnyView (VStack {
            ShowReportTitle(startDate: $startDate, endDate:$endDate, currentPage: 2, totalPages: 3)
            ShowReportSegment(startDate: $startDate, endDate:$endDate, segment:1, records: formatRecords(records: bpDetailResults))
        })
        
        let page3Content = AnyView (VStack {
            ShowReportTitle(startDate: $startDate, endDate:$endDate, currentPage: 3, totalPages: 3)
            ShowBPMaxMin(mmHgSorted: mmHgSorted)
        })
        
        let document1 = PDFDocument(format: .a4)
        let p1image = page1Content.snapshotForPrint()
        var imageElement = PDFImage(image: p1image!)
        document1.add(image: imageElement)
        
        let document2 = PDFDocument(format: .a4)
        let p2image = page2Content.snapshotForPrint()
        imageElement = PDFImage(image: p2image!)
        document2.add(image: imageElement)
        
        let document3 = PDFDocument(format: .a4)
        let p3image = page3Content.snapshotForPrint()
        imageElement = PDFImage(image: p3image!)
        document3.add(image: imageElement)
        let generator = PDFMultiDocumentGenerator(documents: [document1, document2, document3])
        return (try? generator.generateURL(filename: "Example.pdf"))!
    }
        
        
        @MainActor
        func printDocumentView(_ printableView: some View) {
                // Create image for printing
            let imageForPrinting = printableView.snapshotForPrint()!
            
                // Parse image into three pages by successively cropping the printable image
            var pageImages : [UIImage] = []
            let documentHeight = imageForPrinting.size.height
            let pageHeight = 735.0 // was 1201 // May need to adjust through trial and error if size of document changes.
            
            var yOffset = 0.0
            
            while yOffset < documentHeight {
                let sourceImage = imageForPrinting.cgImage
                let cropRect = CGRect(x: 0, y: yOffset, width: imageForPrinting.size.width, height: pageHeight)
                let croppedImage = sourceImage?.cropping(to: cropRect)
                let pageImage = UIImage(cgImage: croppedImage!)
                pageImages.append(pageImage)
                yOffset += pageHeight
            }
            
                // Setup for printing
            let info = UIPrintInfo(dictionary: nil)
            info.outputType = .general
            info.jobName = "Standard Printer Job"
            let printView = UIPrintInteractionController.shared
            printView.printingItems = pageImages
            printView.printInfo = info
            
                // Print!
            printView.present(animated: true)
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
    var currentPage = 0
    var totalPages = 0
    
    var body: some View {
        VStack {
            HStack {
                Text("Blood Pressure Results  -  \(Date().formatted(date: .numeric, time: .omitted))").fontWeight(.bold)
                if currentPage != 0 {
                    Text(", Page \(currentPage) of \(totalPages)").fontWeight(.bold)
                }
            }.padding(.bottom, 20)
            Text("Date range: (\(startDate.formatted(date: .numeric, time: .omitted))-\(endDate.formatted(date: .numeric, time: .omitted)))")
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .padding(.bottom, 20)
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

struct ShowBPMaxMin: View {
    var mmHgSorted: [BPDetails]
    let grid2Member = [GridItem(.fixed(175), alignment: .leading), GridItem(.fixed(75), alignment: .leading)]
    
    var body: some View {
        if mmHgSorted.count >= 20 {
            VStack {
                Text("Ten highest BP readings").fontWeight(.bold)
                let firstHighIndex = mmHgSorted.count-10
                
                ForEach(Array(mmHgSorted[firstHighIndex..<firstHighIndex+10].reversed()), id: \.self) { bpRecord in
                    LazyVGrid(columns: grid2Member) {
                        Text(bpRecord.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened)).font(.subheadline)
                        Text("\(bpRecord.systalic)/\(bpRecord.distalic)").font(.subheadline)
                    }.id(bpRecord.id)
                }
            }.font(.subheadline).padding(.top, 15)
            
            VStack {
                Text("Ten lowest BP readings").fontWeight(.bold)
                let firstHighIndex = 0
                
                ForEach(Array(mmHgSorted[firstHighIndex..<firstHighIndex+10]), id: \.self) { bpRecord in
                    LazyVGrid(columns: grid2Member) {
                        Text(bpRecord.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened)).font(.subheadline)
                        Text("\(bpRecord.systalic)/\(bpRecord.distalic)").font(.subheadline)
                    }.id(bpRecord.id)
                }
            }.font(.subheadline).padding(.vertical, 15)
        } else {
            Text("Insufficent number of readings to report ten highest and lowest readings")
                .padding(.top, 20)
                .fontWeight(.bold)
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    var url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()

        pdfView.document = PDFDocument(url: self.url)

        pdfView.autoScales = false
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
    }
}
