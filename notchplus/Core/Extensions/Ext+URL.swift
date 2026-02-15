//
//  Ext+URL.swift
//  NotchDrop
//
//  Created by Eduardo Monteiro on 15/11/2024.
//

import Foundation
import QuickLook
import SwiftUI

extension URL {
    func snapshotPreview() -> NSImage {
        if let preview = QLThumbnailImageCreate(
            kCFAllocatorDefault,
            self as CFURL,
            CGSize(width: 128, height: 128),
            nil
        )?.takeRetainedValue() {
            return NSImage(cgImage: preview, size: .zero)
        }

        return NSWorkspace.shared.icon(forFile: path)
    }

    // refactor this function using QuickLookThumbnailing

}


// FIXME: update QLThumbnailImageCreate to use QuickLookThumbnailing
// import QuickLookThumbnailing not working

//extension URL {
//    func snapshotPreview() -> NSImage? {
//        let size = CGSize(width: 128, height: 128)
//        let scale = NSScreen.main?.backingScaleFactor ?? 1.0
//        let request = QLThumbnailGenerator.Request(fileAt: self, size: size, scale: scale, representationTypes: .all)
//
//        let generator = QLThumbnailGenerator.shared
//        var thumbnailImage: NSImage?
//
//        let semaphore = DispatchSemaphore(value: 0)
//
//        generator.generateBestRepresentation(for: request) { (thumbnail, error) in
//            if let thumbnail = thumbnail {
//                thumbnailImage = thumbnail.nsImage
//            } else {
//                thumbnailImage = NSWorkspace.shared.icon(forFile: self.path)
//            }
//            semaphore.signal()
//        }
//
//        semaphore.wait()
//        return thumbnailImage
//    }
//}
