//
//  DragDropView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 04/11/24.
//

import SwiftUI
import AppKit

class DragDropView: NSView {
    var onDragEntered: () -> Void = {}
    var onDragExited: () -> Void = {}
    var onDrop: () -> Void = {}
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder) has not been implemented")
    }
    
    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        onDragEntered()
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        onDragExited()
    }
    
    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        onDrop()
        return true
    }
}

struct DragDropViewRepresentable: NSViewRepresentable {
    @Binding var isTargeted: Bool
    var onDrop: () -> Void
    
    func makeNSView(context: Context) -> DragDropView {
        let view = DragDropView()
        view.onDragEntered = { isTargeted = true }
        view.onDragEntered = { isTargeted = false }
        view.onDrop = onDrop
        
        view.autoresizingMask = [.width, .height]
        
        return view
    }
    
    func updateNSView(_ nsView: DragDropView, context: Context) { }
}
