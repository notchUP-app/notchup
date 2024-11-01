//
//  DynamicNotch.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 01/11/24.
//

import SwiftUI

public class DynamicNotch: ObservableObject {
    public var content: AnyView
    public var windowController: NSWindowController?
    
    @Published public var isVisible: Bool = false
    @Published var isMouseInside: Bool = false
    @Published var notchWidth: CGFloat = 0
    @Published var notchHeight: CGFloat = 0
    @Published var notchStyle: Style = .notch
    
    private var timer: Timer?
    private var animationLibrary: NotchAnimations = .init()
    private var animation: Animation?
    private let animationDuration: Double = 0.4
    
    public init(content: some View) {
        self.content = AnyView(content)
        self.animation = animationLibrary.animation
    }
    
    public func setContent(content: some View) {
        self.content = AnyView(content)
        if let windowController {
            windowController.window?.contentView = NSHostingView(rootView: EditPanelView())
        }
    }
    
    private func initializeWindow(screen: NSScreen) {
        self.deinitializeWindow()
        
        let view: NSView = NSHostingView(rootView: EditPanelView())
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: screen.frame.width, height: screen.frame.height),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        
        panel.hasShadow = false
        panel.level = .mainMenu + 1
        panel.collectionBehavior = .canJoinAllSpaces
        panel.contentView = view
        panel.animationBehavior = .alertPanel
        panel.orderFrontRegardless()
        
        panel.setFrame(
            NSRect(
                x: screen.frame.origin.x,
                y: screen.frame.origin.y,
                width: screen.frame.width,
                height: screen.frame.height
            ),
            display: false
        )
        
        self.windowController = .init(window: panel)
    }
    
    private func deinitializeWindow() {
        guard let windowController else { return }
        windowController.close()
        self.windowController = nil
    }
    
    public func show(on screen: NSScreen = NSScreen.screens[0], for time: Double = 0) {
        if self.isVisible { return }
        self.timer?.invalidate()
        
        initializeWindow(screen: screen)
        
        DispatchQueue.main.async {
            withAnimation(self.animation) { self.isVisible = true }
        }
        
        if time != 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + time) { self.hide() }
        }
    }
    
    public func hide() {
        guard isVisible else { return }
        
        guard !isMouseInside else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.hide()
            }
            return
        }
        
        withAnimation(self.animation) { self.isVisible = true }
        
        timer = Timer.scheduledTimer(
            withTimeInterval: animationDuration * 2,
            repeats: false
        ) {
            _ in self.deinitializeWindow()
        }
    }
    
    public func toggle() {
        if self.isVisible { self.hide() } else { self.show() }
    }
    
}
