    //
    //  ReportView.swift
    //  BPTracker
    //
    //  Created by Mark A Stewart on 4/5/24.
    //

import SwiftUI
import SwiftData
import PDFKit
import PrintingKit

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
            let pageCount = Int((Double (dataForReport.count) / Double (recordsPerPage)).rounded(.up))
            var startIndex = 0
            var endIndex = dataForReport.count > recordsPerPage ? recordsPerPage : dataForReport.count
            var remainingRecs: Int
            
            for page in 1...pageCount {
                let dataForPage = Array(dataForReport[startIndex..<endIndex])
                views.append(AnyView(PdfPage(dailyReadings: dataForPage, startDate: $startDate, endDate: $endDate, pageNum: page, pageCount: pageCount)))
                startIndex += recordsPerPage
                remainingRecs = dataForReport.count - endIndex
                endIndex = remainingRecs < recordsPerPage ? endIndex + remainingRecs : endIndex + recordsPerPage
            }
            //views.append(AnyView(ShowBPMaxMin(mmHgSorted: filteredmmHGResults, startDate: $startDate, endDate: $endDate, pageNum: pageCount, pageCount: pageCount)))
            
            let outputFileURL = try! createPdf("BPResultReport.pdf", width: 325, height: 820, views: views )
            pdfUrl = outputFileURL
        }
        
        HStack {
            Button {
                try? Printer().print(PrintItem.pdfFile(at: pdfUrl))
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
    
    func reportModel(filteredDetails: [BPDetails]) -> [PdfPage.DailyReadings] {
        let uniqueTimeStamps = filteredDetails.compactMap { Calendar.current.startOfDay(for: $0.timestamp) }.distinct()
        var dailyReadings : [PdfPage.DailyReadings] = []
        let maxRecordsPerLine = 3
        
        for dailyTimeStamp in 0..<uniqueTimeStamps.count {
            var dailyReading = PdfPage.DailyReadings(date: "", readings: [])
            let modifiedDate = Calendar.current.date(byAdding: .day, value: 1, to: uniqueTimeStamps[dailyTimeStamp])
            let recordsForDay = filteredDetails.filter({$0.timestamp >= uniqueTimeStamps[dailyTimeStamp] && $0.timestamp < modifiedDate!})
            let recordsForRow = recordsForDay.count > maxRecordsPerLine ? maxRecordsPerLine : recordsForDay.count
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yy"
            
            dailyReading.date = dateFormatter.string(from: uniqueTimeStamps[dailyTimeStamp])
            for dailyRecIndex in 0..<recordsForRow{
                let readingTime = timeFormatter.string(from: recordsForDay[dailyRecIndex].timestamp)
                let systolicString = String (recordsForDay[dailyRecIndex].systalic)
                let distalicString = String (recordsForDay[dailyRecIndex].distalic)
                var thisReading = PdfPage.Reading(eachReading: "")
                thisReading.eachReading = readingTime + " " + systolicString + "/" + distalicString
                dailyReading.readings.append(thisReading)
            }
            dailyReadings.append(dailyReading)
        }
        return dailyReadings
    }
}

struct PdfPage: View {
    var dailyReadings: [DailyReadings]
    @Binding var startDate: Date
    @Binding var endDate: Date
    var pageNum: Int
    var pageCount: Int

    struct Reading: Identifiable, Equatable {
        var id = UUID()
        var eachReading: String
    }

    struct DailyReadings: Identifiable, Equatable {
        var id = UUID()
        var date: String
        var readings: [Reading]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ShowReportTitle(startDate: $startDate, endDate: $endDate)

            Grid {
                GridRow {
                    Text("Date")
                    Text("Reading1")
                    Text("Reading2")
                    Text("Reading3")
                }
                .bold()
                Divider()
                ForEach(dailyReadings) { readingRec in
                    GridRow {
                        Text(readingRec.date)
                        ForEach(readingRec.readings) { reading in
                            Text(reading.eachReading)
                        }
                    }.font(.caption2)
                    if readingRec != dailyReadings.last {
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
            Text("Blood Pressure Results  -  \(Date().formatted(date: .numeric, time: .omitted))")
            Text("Date range: (\(startDate.formatted(date: .numeric, time: .omitted))-\(endDate.formatted(date: .numeric, time: .omitted)))")
        }
        .font(.system(size: 14))
        .fontWeight(.bold).padding(.bottom, 20)
    }
}

struct ShowReportFooter: View {
    var pageNum: Int
    var pageCount: Int
    
    var body: some View {
        Text("")
        Text("Page \(pageNum) of \(pageCount)").font(.caption2)
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
