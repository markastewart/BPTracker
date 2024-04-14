//
//  PDfRender.swift
//  BPTracker
//
//  Created by Mark A Stewart on 4/14/24.
//

import Foundation
import SwiftUI

func createUrl(fileName: String) throws -> URL {
    let fileManager = FileManager.default
    let url = fileManager.temporaryDirectory.appendingPathComponent(fileName, conformingTo: .pdf)
    if fileManager.fileExists(atPath: url.path) {
        try fileManager.removeItem(at: url)
    }
    return url
}

func createPdf(_ fileName: String, width:CGFloat=595.2, height:CGFloat=841.8, views: [AnyView]) throws -> URL {
    let format = UIGraphicsPDFRendererFormat()
    let url = try createUrl(fileName: fileName)
    let pdfRect = CGRect(x: 0, y: 0, width: width, height: height)
    let pdfRenderer = UIGraphicsPDFRenderer(bounds: pdfRect, format: format)
    
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
