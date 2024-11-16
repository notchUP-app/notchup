//
//  AppDelegate.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 18/10/24.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel: NotchViewModel = .init()
    var window: NotchUpWindow!
    var animationWindow: NSWindow?
    let sizing: Sizes = .init()
    private var previousScreens: [NSScreen]?
    
    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        
        viewModel.setupWorkersNotificationsObservers()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustWindowPosition),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(forName: Notification.Name.selectedScreenChanged, object: nil, queue: nil) { [ weak self ] _ in
            self?.adjustWindowPosition()
        }
        
        adjustWindowPosition()
        
        showAnimationOverlay()
    }
    
    @objc func adjustWindowPosition() {
        guard let window = window else { return }
        
        if !NSScreen.screens.contains(where: {$0.localizedName == viewModel.selectedScreen}) {
            viewModel.selectedScreen = NSScreen.main?.localizedName ?? "Unknown Screen"
        }
        
        let selectedScreen = NSScreen.screens.first(where: {$0.localizedName == viewModel.selectedScreen})
        closedNotchSize = setNotchSize(screen: selectedScreen?.localizedName)
        
        if let screenFrame = selectedScreen {
            DispatchQueue.main.async {
                let origin = screenFrame.frame.origin.applying(
                    CGAffineTransform(
                        translationX: (screenFrame.frame.width / 2) - window.frame.width / 2,
                        y: screenFrame.frame.height - window.frame.height
                    )
                )
                
                window.setFrameOrigin(origin)
            }
        }
    }
    
    private func showAnimationOverlay() {
        animationWindow = NSWindow(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        animationWindow?.level = .mainMenu + 1
        animationWindow?.backgroundColor = .clear
        animationWindow?.isOpaque = false
        animationWindow?.ignoresMouseEvents = true
        
        animationWindow?.contentView = NSHostingView(
            rootView: LaunchAnimationView {
                DispatchQueue.main.async {
                    self.createAndShowMainWindow()
                    self.animationWindow?.orderOut(nil)
                    self.animationWindow = nil
                }
            }
        )
        
        animationWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func createAndShowMainWindow() {
        self.window = NotchUpWindow(
            contentRect: NSRect(x: 0, y: 0, width: sizing.size.opened.width! + 20 , height: sizing.size.opened.height! + 30),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        self.window?.contentView = NSHostingView(
            rootView: ContentView(onHover: adjustWindowPosition, batteryModel: .init(viewModel: self.viewModel))
                .environmentObject(viewModel)
                .environmentObject(MusicManager(viewModel: viewModel)!)
        )
        
        adjustWindowPosition()
        
        self.window?.alphaValue = 1
        self.window?.makeKeyAndOrderFront(nil)
    }
}
