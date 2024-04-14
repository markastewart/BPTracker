//
//  Extensions.swift
//  BPTracker
//
//  Created by Mark A Stewart on 4/14/24.
//

import SwiftUI

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

public extension Array where Element: Hashable {
    func distinct() -> Array<Element> {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
