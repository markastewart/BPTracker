    //
    //  ReportView.swift
    //  BPTracker
    //
    //  Created by Mark A Stewart on 4/5/24.
    //

import SwiftUI
import SwiftData
import PDFKit

struct ShowResults: View {
    @Query(sort: \BPDetails.timestamp) var bpDetailResults: [BPDetails]
    @Binding var showResults: Bool
    @State var startDate = Date()
    @State var endDate = Date()
    @State var showReport = false
    
    var body: some View {
        HStack {
            Spacer()
            Text("Select Date Range for Results").font(.headline).padding(.vertical, 35)
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
    @Query(sort: \BPDetails.timestamp, order: .reverse) var bpDetailResults: [BPDetails]
    @Query(sort: \BPDetails.totalmmHg) var mmHgSorted: [BPDetails]
    @State var pdfUrl: URL?
    @Binding var showReport: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    var views: [AnyView] = []
    var filteredBPResults: [BPDetails] {
        return bpDetailResults.compactMap { detailRec in
            return detailRec.timestamp >= startDate && detailRec.timestamp <= endDate ? detailRec : nil
        }
    }
    var filteredmmHGResults: [BPDetails] {
        return mmHgSorted.compactMap { detailRec in
            return detailRec.timestamp >= startDate && detailRec.timestamp <= endDate ? detailRec : nil
        }
    }
    
    var body: some View {
        var views: [AnyView] = []
        
        VStack {
            if let pdfUrl = pdfUrl {
                PdfFileView(url: pdfUrl)
            }
        }
        .padding()
        .onAppear {
            let dataForReport = reportModel(filteredDetails: filteredBPResults)
            let recordsPerPage = 25
            let pageCount = max(1, Int((Double(dataForReport.count) / Double(recordsPerPage)).rounded(.up)))
            var startIndex = 0
            
            if !dataForReport.isEmpty {
                for page in 1...pageCount {
                    let endIndex = min(startIndex + recordsPerPage, dataForReport.count)
                    let dataForPage = Array(dataForReport[startIndex..<endIndex])
                    views.append(AnyView(PdfPage(readings: dataForPage, startDate: $startDate, endDate: $endDate, pageNum: page, pageCount: pageCount)))
                    startIndex = endIndex
                }
            }
            
            let outputFileURL = try! createPdf("BPResultReport.pdf", width: 325, height: 820, views: views)
            pdfUrl = outputFileURL
        }
        
        HStack {
            Button {
                if let pdfUrl {
                    let printController = UIPrintInteractionController.shared
                    printController.printingItem = pdfUrl
                    printController.present(animated: true)
                }
            } label: {
                Text("Print")
                Image(systemName: "printer")
            }
            .buttonStyle(BorderedButtonStyle())
            
            Spacer()
            Button("Cancel") {
                showReport = false
            }
        }.padding(.horizontal, 50).padding(.vertical, 20)
            .font(.subheadline)
    }
    
    func reportModel(filteredDetails: [BPDetails]) -> [PdfPage.ReportRow] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        var rows: [PdfPage.ReportRow] = []
        var lastDay: Date?
        
        for record in filteredDetails {
            let recordDay = Calendar.current.startOfDay(for: record.timestamp)
            let dateText = (recordDay == lastDay) ? "" : dateFormatter.string(from: record.timestamp)
            lastDay = recordDay
            
            let timeText = timeFormatter.string(from: record.timestamp)
            let readingText = "\(record.systalic)/\(record.distalic) (\(record.pulse))"
            
            rows.append(PdfPage.ReportRow(dateText: dateText, timeText: timeText, readingText: readingText))
        }
        return rows
    }
}

struct PdfPage: View {
    var readings: [ReportRow]
    @Binding var startDate: Date
    @Binding var endDate: Date
    var pageNum: Int
    var pageCount: Int
    
    struct ReportRow: Identifiable, Equatable {
        var id = UUID()
        var dateText: String
        var timeText: String
        var readingText: String
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ShowReportTitle(startDate: $startDate, endDate: $endDate)
            
            Grid {
                GridRow {
                    Text("Date")
                    Text("Time")
                    Text("BP / Pulse")
                }
                .bold()
                Divider()
                ForEach(readings) { row in
                    GridRow {
                        Text(row.dateText)
                        Text(row.timeText)
                        Text(row.readingText)
                    }.font(.caption2)
                    if row != readings.last {
                        Divider()
                    }
                }
            }
            .font(.caption2)
            .frame(width: 300)
            
            ShowReportFooter(pageNum: pageNum, pageCount: pageCount)
        }
        .background(Color.white)
        .frame(width: 300)
    }
}

struct ShowBPMaxMin: View {
    var mmHgSorted: [BPDetails]
    @Binding var startDate: Date
    @Binding var endDate: Date
    let grid2Member = [GridItem(.fixed(175), alignment: .leading), GridItem(.fixed(75), alignment: .leading)]
    var pageNum: Int
    var pageCount: Int
    
    var body: some View {
        ShowReportTitle(startDate: $startDate, endDate: $endDate)
        
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
            }.font(.caption2).padding(.top, 15)
            
            VStack {
                Text("Ten lowest BP readings").fontWeight(.bold)
                let firstHighIndex = 0
                
                ForEach(Array(mmHgSorted[firstHighIndex..<firstHighIndex+10]), id: \.self) { bpRecord in
                    LazyVGrid(columns: grid2Member) {
                        Text(bpRecord.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened)).font(.subheadline)
                        Text("\(bpRecord.systalic)/\(bpRecord.distalic)").font(.subheadline)
                    }.id(bpRecord.id)
                }
            }.font(.caption2).padding(.vertical, 15)
        } else {
            Text("Insufficent number of readings to report ten highest and lowest readings")
                .padding(.top, 20)
                .fontWeight(.bold)
        }
        
        ShowReportFooter(pageNum: pageNum, pageCount: pageCount)
    }
}

struct ShowReportTitle: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    var currentPage = 0
    var totalPages = 0
    
    var body: some View {
        VStack {
            Text("BP/Pulse Results  -  \(Date().formatted(date: .numeric, time: .omitted))")
            Text("Date range: (\(startDate.formatted(date: .numeric, time: .omitted))-\(endDate.formatted(date: .numeric, time: .omitted)))")
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .font(.system(size: 14))
        .fontWeight(.bold).padding(.bottom, 20)
    }
}

struct ShowReportFooter: View {
    var pageNum: Int
    var pageCount: Int
    
    var body: some View {
        Text("Page \(pageNum) of \(pageCount)").font(.caption2)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct PdfFileView : UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> some PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        
        return pdfView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
