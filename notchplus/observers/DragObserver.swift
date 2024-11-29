//
//  DragObserver.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 28/11/24.
//

import SwiftUI
import Cocoa

class DragObserver {
    private var monitoring: Bool = false
    private var lastChangeCount: Int = 0
    private var lastMousePosition: NSPoint?
    private var viewModel: NotchViewModel
    
    init(viewModel: NotchViewModel) {
        self.viewModel = viewModel
    }
    
    func startMonitoring() {
        guard !monitoring else { return }
        monitoring = true
        
        let pasteboard = NSPasteboard(name: .drag)
        lastChangeCount = pasteboard.changeCount
        
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            self?.checkPasteboard(pasteboard, event: event)
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { event in
            print("Drag ended.")
            self.viewModel.close()
        }
    }
    
    private func checkPasteboard(_ pasteboard: NSPasteboard, event: NSEvent) {
        let changeCount = pasteboard.changeCount
        
        if lastChangeCount != changeCount {
            if let lastPosition = lastMousePosition {
                let currentPosition = event.locationInWindow
                if currentPosition.y > lastPosition.y {
                    // only files are accepted
                    if pasteboard.canReadObject(forClasses: [NSURL.self], options: nil) {
                        print("Drag started.")
                        self.viewModel.open()
                    }
                    
                    lastChangeCount = changeCount
                    lastMousePosition = currentPosition
                }
            } else {
                lastMousePosition = event.locationInWindow
            }
        }
    }
    
    func stopMonitoring() {
        monitoring = false
    }
}
