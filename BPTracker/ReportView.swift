//
//  ReportView.swift
//  BPTracker
//
//  Created by Mark A Stewart on 4/5/24.
//

import SwiftUI
import SwiftData
//import TPPDF
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

extension Array where Element: Hashable {
    func distinct() -> Array<Element> {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
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
    
    @State var pdfUrl: URL?
    var body: some View {
        VStack {
          if let pdfUrl = pdfUrl {
            PdfFileView(url: pdfUrl)
          }
        }
        .onAppear {
          do {
            let views: [AnyView] = [
                //AnyView(CreatePDFView.Page1()),
                AnyView(ShowBPMaxMin(mmHgSorted: mmHgSorted)),
                AnyView(CreatePDFView.Page2()),
                AnyView(CreatePDFView.Page3()),
            ]
            let url = try createPdf("sample.pdf",
                                    options: pdfRendererFormat,
                                    views: views)
            pdfUrl = url
            print(url.path)
          } catch {
            print(error.localizedDescription)
          }
        }
//        VStack {
//            if let pdfUrl = pdfUrl {
//                PdfFileView(url: pdfUrl)
//            }
//        }
//        .padding()
//        .onAppear {
//            let outputFileURL = try! PdfPage(dailyReadings: reportModel(filteredDetails: filteredDetails),startDate: $startDate, endDate: $endDate).exportToPDF("sample.pdf", width: 350, height: 850 )
//            pdfUrl = outputFileURL
//            print("URL = \(String(describing: pdfUrl))")
//        }
//        //let url = render()
//        PDFKitView(url: url)
//            .onAppear {
//                print("URL = \(url)")
//            }
        
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
    
//    @MainActor func render() -> URL {
//        var ourDocs : [TPPDF.PDFDocument] = []
//        let recordsPerPage = 20
//        let recordCount = filteredDetails.count
//        let pageCount = Int((Double (recordCount) / Double (recordsPerPage)).rounded(.up))
//        var currentIndex = 0
//        
//        for currentPage in 0..<pageCount {
//            let recordsInPage = (pageCount-1) == currentPage ? (filteredDetails.count - (currentPage * recordsPerPage)) : recordsPerPage
//            currentIndex = currentPage == 0 ? 0 : currentIndex+recordsPerPage
//            
//            let pageContent = AnyView (VStack {
//                ShowReportTitle(startDate: $startDate, endDate:$endDate, currentPage: currentPage+1, totalPages: pageCount+1)
//                ShowReportSegment(startIndex: currentIndex, recordsToReport: recordsInPage, records: formatRecords(records: filteredDetails))
//                ShowReportFooter(currentPage: currentPage+1, totalPages: pageCount+1)
//            })
//            let document = PDFDocument(format: .a4)
//            let image = pageContent.snapshotForPrint()
//            let imageElement = PDFImage(image: image!)
//            document.add(image: imageElement)
//            ourDocs.append(document)
//        }
//        
//        let pageContent = AnyView (VStack {
//            ShowReportTitle(startDate: $startDate, endDate:$endDate, currentPage: pageCount+1, totalPages: pageCount+1)
//            ShowBPMaxMin(mmHgSorted: mmHgSorted)
//            ShowReportFooter(currentPage: pageCount+1, totalPages: pageCount+1)
//        })
//        let document = PDFDocument(format: .a4)
//        let image = pageContent.snapshotForPrint()
//        let imageElement = PDFImage(image: image!)
//        document.add(image: imageElement)
//        ourDocs.append(document)
//        
//        let generator = PDFMultiDocumentGenerator(documents: ourDocs)
//        return (try? generator.generateURL(filename: "BPResults.pdf"))!
//    }
    
//    func formatRecords(records: [BPDetails]) -> [String] {
//        return records.map { record in
//            return "\(record.timestamp.formatted(date: .numeric, time: .shortened)): \(record.systalic)/\(record.distalic) mmHg"
//        }
//    }
    
    func reportModel(filteredDetails: [BPDetails]) -> [PdfPage.DailyReadings] {
        let uniqueTimeStamps = filteredDetails.compactMap { Calendar.current.startOfDay(for: $0.timestamp) }.distinct()
        var dailyReadings : [PdfPage.DailyReadings] = []
        let maxRecordsPerLine = 3
        
        for dailyTimeStamp in 0..<uniqueTimeStamps.count {
            var dailyReading = PdfPage.DailyReadings(date: "", readings: [])
            let modifiedDate = Calendar.current.date(byAdding: .day, value: 1, to: uniqueTimeStamps[dailyTimeStamp])
            let recordsForDay = filteredDetails.filter({$0.timestamp >= uniqueTimeStamps[dailyTimeStamp] && $0.timestamp < modifiedDate!})
            let recordsForLine = recordsForDay.count > maxRecordsPerLine ? maxRecordsPerLine : recordsForDay.count
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yy"
            
            dailyReading.date = dateFormatter.string(from: uniqueTimeStamps[dailyTimeStamp])
            for dailyRecIndex in 0..<recordsForLine{
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

struct PdfPage : View {
    var dailyReadings: [DailyReadings]
    @Binding var startDate: Date
    @Binding var endDate: Date
    
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
        ShowReportTitle(startDate: $startDate, endDate: $endDate)
        
        List {
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
        }
        .font(.caption2)
        .frame(width: 380, height: 600)
        
        ShowReportFooter(currentPage: 1, totalPages: 3)
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

//struct ShowReportSegment: View {
//    var startIndex : Int
//    var recordsToReport : Int
//    var records : [String]
//    
//    var body: some View {
//        ForEach (0..<recordsToReport, id: \.self) { nextPageIndex in
//            Text("\(records[startIndex+nextPageIndex])")
//                .font(.system(size: 14))
//            Divider()
//        }
//    }
//}

struct ShowReportFooter: View {
    var currentPage: Int
    var totalPages: Int
    
    var body: some View {
        Text("")
        Text("Page \(currentPage) of \(totalPages)").font(.caption2)
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

//struct PDFKitView: UIViewRepresentable {
//    var url: URL
//    
//    func makeUIView(context: Context) -> PDFView {
//        let pdfView = PDFView()
//        pdfView.document = PDFDocument(url: self.url)
//        pdfView.autoScales = false
//        return pdfView
//    }
//    
//    func updateUIView(_ pdfView: PDFView, context: Context) {
//    }
//}

//func createUrl(fileName: String) throws -> URL {
//    let fileManager = FileManager.default
//    let url = fileManager.temporaryDirectory.appendingPathComponent(fileName, conformingTo: .pdf)
//    if fileManager.fileExists(atPath: url.path) {
//        try fileManager.removeItem(at: url)
//    }
//    return url
//}

extension View {
    func exportToPDF(_ fileName: String, width:CGFloat=595.2, height:CGFloat=841.8) throws -> URL {
        let outputFileURL = try createUrl(fileName: fileName)
        let pdfVC = UIHostingController(rootView: self)
        pdfVC.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
            //Render the view behind all other views
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
//        let window = windowScene?.windows.first
        let window = windowScene?.windows.last
        
        let rootVC = window?.rootViewController
        rootVC?.addChild(pdfVC)
        rootVC?.view.insertSubview(pdfVC.view, at: 0)
            //Render the PDF
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: width, height: height))
        try pdfRenderer.writePDF(to: outputFileURL, withActions: { context in
            context.beginPage()
            rootVC?.view.layer.render(in: context.cgContext)
        })
        
        pdfVC.removeFromParent()
        pdfVC.view.removeFromSuperview()
        
        return outputFileURL
    }
}




// add all new

let pdfRendererFormat = [:
//  kCGPDFContextCreator: "@mbotsu",
//  kCGPDFContextAuthor: "@mbotsu",
//  kCGPDFContextTitle: "Create multi-page PDFs with SwiftUI layouts",
//  kCGPDFContextSubject: "Give up ImageRenderer and create PDFs with UIGraphicsPDFRenderer",
] as [String : Any]

struct CreatePDFView: View {
    @Query(sort: \BPDetails.totalmmHg) var mmHgSorted: [BPDetails]
  @State var pdfUrl: URL?
  
  var body: some View {
    VStack {
      if let pdfUrl = pdfUrl {
        PdfFileView(url: pdfUrl)
      }
    }
    .onAppear {
      do {
        let views: [AnyView] = [
          //AnyView(Page1()),
            AnyView(ShowBPMaxMin(mmHgSorted: mmHgSorted)),
          AnyView(Page2()),
          AnyView(Page3()),
        ]
        let url = try createPdf("sample.pdf",
                                options: pdfRendererFormat,
                                views: views)
        pdfUrl = url
        print(url.path)
      } catch {
        print(error.localizedDescription)
      }
    }
  }
  
  struct Page1: View {
    var body: some View {
      Text("Page1")//.font(.largeTitle)
    }
  }
  
  struct Page2: View {
    var body: some View {
      Text("Page2").font(.largeTitle)
    }
  }
  
  struct Page3: View {
    var body: some View {
      Text("Page3").font(.largeTitle)
    }
  }
}

func createUrl(fileName: String) throws -> URL {
  let fileManager = FileManager.default
  let url = fileManager.temporaryDirectory.appendingPathComponent(fileName, conformingTo: .pdf)
  if fileManager.fileExists(atPath: url.path) {
    try fileManager.removeItem(at: url)
  }
  return url
}

func createPdf(_ fileName: String, options: [String: Any],
               width:CGFloat=595.2, height:CGFloat=841.8,
               views: [AnyView]) throws -> URL {
  
  let format = UIGraphicsPDFRendererFormat()
  format.documentInfo = options
  
  let url = try createUrl(fileName: fileName)
  let pdfRect = CGRect(x: 0, y: 0, width: width, height: height)
  //let pdfRenderer = UIGraphicsPDFRenderer(bounds: pdfRect, format: format)
    let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: width, height: height))
  
  guard let rootVC = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
    .windows.last?.rootViewController else {
    throw NSError(domain: "rootViewController NotFound", code: -1)
  }
  
  try pdfRenderer.writePDF(to: url , withActions: { context in
    views.forEach{ view in
      _createPdf(view, rect: pdfRect, context: context, rootViewController: rootVC)
    }
  })
  
  return url
}

func _createPdf(_ view: AnyView, rect: CGRect,
                context: UIGraphicsPDFRendererContext, rootViewController: UIViewController){
  
  let vc = UIHostingController(rootView: view)
  vc.view.frame = rect
  rootViewController.addChild(vc)
  rootViewController.view.insertSubview(vc.view, at: 0)
  
  context.beginPage()
  context.cgContext.clear(rect)
  rootViewController.view.layer.render(in: context.cgContext)
  
  vc.removeFromParent()
  vc.view.removeFromSuperview()
}

struct PdfFileView : UIViewRepresentable {
  let url: URL
  
  func makeUIView(context: Context) -> some PDFView {
    let pdfView = PDFView()
    pdfView.document = PDFDocument(url: url)
    pdfView.autoScales = true
    pdfView.displayMode = .singlePageContinuous // .twoUpContinuous
    
    return pdfView
  }
  func updateUIView(_ uiView: UIViewType, context: Context) {}
}
