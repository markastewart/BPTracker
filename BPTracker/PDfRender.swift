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

@MainActor
func createPdf(_ fileName: String, width: CGFloat = 595.2, height: CGFloat = 841.8, views: [AnyView]) throws -> URL {
    let format = UIGraphicsPDFRendererFormat()
    let url = try createUrl(fileName: fileName)
    let pdfRect = CGRect(x: 0, y: 0, width: width, height: height)
    let pdfRenderer = UIGraphicsPDFRenderer(bounds: pdfRect, format: format)

    try pdfRenderer.writePDF(to: url, withActions: { context in
        views.forEach { view in
            _createPdf(view, rect: pdfRect, context: context)
        }
    })
    return url
}

@MainActor
func _createPdf(_ view: AnyView, rect: CGRect, context: UIGraphicsPDFRendererContext) {
    let hostingController = UIHostingController(rootView: view)
    hostingController.view.frame = rect
    hostingController.view.backgroundColor = .white   // was .clear

    let renderWindow = UIWindow(frame: rect)
    renderWindow.backgroundColor = .white
    renderWindow.rootViewController = hostingController
    renderWindow.windowLevel = .alert + 1
    renderWindow.alpha = 0.01
    renderWindow.isHidden = false
    hostingController.view.layoutIfNeeded()

    context.beginPage()
    context.cgContext.setFillColor(UIColor.white.cgColor)
    context.cgContext.fill(rect)                      // was context.cgContext.clear(rect)
    hostingController.view.layer.render(in: context.cgContext)

    renderWindow.isHidden = true
    renderWindow.rootViewController = nil
}
