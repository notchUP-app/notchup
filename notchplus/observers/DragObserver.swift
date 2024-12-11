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
    private var upwardMovementThreshold: CGFloat = 5.0
    private var downwardMovementThreshold: CGFloat = -5.0
    
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
        
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self?.viewModel.close()
                self?.resetPasteboardChangeCount(pasteboard)
            }
        }
    }
    
    private func checkPasteboard(_ pasteboard: NSPasteboard, event: NSEvent) {
        if pasteboard.changeCount != lastChangeCount {
            if let lastPosition = lastMousePosition {
                let currentPosition = event.locationInWindow
                let movement = currentPosition.y - lastPosition.y
                
                if movement > upwardMovementThreshold {
                    self.viewModel.open()
                } else if movement < downwardMovementThreshold {
                    self.viewModel.close()
                }
                
                lastMousePosition = currentPosition
            } else {
                lastMousePosition = event.locationInWindow
            }
        }
    }
    
    private func resetPasteboardChangeCount(_ pasteboard: NSPasteboard) {
        lastChangeCount = pasteboard.changeCount
    }
    
    func stopMonitoring() {
        monitoring = false
    }
}
