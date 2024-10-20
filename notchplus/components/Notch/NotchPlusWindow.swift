//
//  NotchWindow.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 18/10/24.
//

import SwiftUI

class NotchPlusWindow: NSPanel {
    override init(contentRect: NSRect, styleMask: NSWindow.StyleMask, backing: NSWindow.BackingStoreType, defer flag: Bool ) {
        super.init(contentRect: contentRect, styleMask: styleMask, backing: backing, defer: flag)
        
        isFloatingPanel = true
        isOpaque = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        backgroundColor = .clear
        isMovable = false
        
        isReleasedWhenClosed = false
        level = .mainMenu + 3
        hasShadow = false
        
        collectionBehavior = [ .fullScreenAuxiliary, .stationary, .canJoinAllSpaces, .ignoresCycle ]
        
    }
    
    override var canBecomeKey: Bool { true }
    
    override var canBecomeMain: Bool { true }

}
