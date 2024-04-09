//
//  ReportView.swift
//  BPTracker
//
//  Created by Mark A Stewart on 4/5/24.
//

import SwiftUI
import SwiftData
import TPPDF
import PDFKit
import PrintingKit

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
    
    var filteredDetails: [BPDetails] {
        return bpDetailResults.compactMap { detailRec in
            return detailRec.timestamp >= startDate && detailRec.timestamp <= endDate ? detailRec : nil
        }
    }
    
    var body: some View {
        let url = render()
        PDFKitView(url: url)
            .onAppear {
                print("URL = \(url)")
            }
        
        HStack {
            Button {
                try? Printer().print(PrintItem.pdfFile(at: url))
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
        var ourDocs : [TPPDF.PDFDocument] = []
        let recordsPerPage = 20
        let recordCount = filteredDetails.count
        let pageCount = Int((Double (recordCount) / Double (recordsPerPage)).rounded(.up))
        var currentIndex = 0
        
        for currentPage in 0..<pageCount {
            let recordsInPage = (pageCount-1) == currentPage ? (filteredDetails.count - (currentPage * recordsPerPage)) : recordsPerPage
            currentIndex = currentPage == 0 ? 0 : currentIndex+recordsPerPage
            
            let pageContent = AnyView (VStack {
                ShowReportTitle(startDate: $startDate, endDate:$endDate, currentPage: currentPage+1, totalPages: pageCount+1)
                ShowReportSegment(startIndex: currentIndex, recordsToReport: recordsInPage, records: formatRecords(records: filteredDetails))
                ShowReportFooter(currentPage: currentPage+1, totalPages: pageCount+1)
            })
            let document = PDFDocument(format: .a4)
            let image = pageContent.snapshotForPrint()
            let imageElement = PDFImage(image: image!)
            document.add(image: imageElement)
            ourDocs.append(document)
        }
        
        let pageContent = AnyView (VStack {
            ShowReportTitle(startDate: $startDate, endDate:$endDate, currentPage: pageCount+1, totalPages: pageCount+1)
            ShowBPMaxMin(mmHgSorted: mmHgSorted)
            ShowReportFooter(currentPage: pageCount+1, totalPages: pageCount+1)
        })
        let document = PDFDocument(format: .a4)
        let image = pageContent.snapshotForPrint()
        let imageElement = PDFImage(image: image!)
        document.add(image: imageElement)
        ourDocs.append(document)
        
        let generator = PDFMultiDocumentGenerator(documents: ourDocs)
        return (try? generator.generateURL(filename: "BPResults.pdf"))!
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
            Text("Blood Pressure Results  -  \(Date().formatted(date: .numeric, time: .omitted))")
            Text("Date range: (\(startDate.formatted(date: .numeric, time: .omitted))-\(endDate.formatted(date: .numeric, time: .omitted)))")
        }
        .font(.system(size: 14))
        .fontWeight(.bold).padding(.bottom, 20)
    }
}

struct ShowReportSegment: View {
    var startIndex : Int
    var recordsToReport : Int
    var records : [String]
    
    var body: some View {
        ForEach (0..<recordsToReport, id: \.self) { nextPageIndex in
            Text("\(records[startIndex+nextPageIndex])")
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
