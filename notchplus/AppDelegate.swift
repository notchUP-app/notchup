//
//  AppDelegate.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 18/10/24.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel: NotchViewModel = .init()
    var window: NotchPlusWindow!
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
        
        self.window = NotchPlusWindow(
            contentRect: NSRect(x: 0, y: 0, width: sizing.size.opened.width! + 20 , height: sizing.size.opened.height! + 30),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        self.window.contentView = NSHostingView(
            rootView: ContentView(onHover: adjustWindowPosition, batteryModel: .init(viewModel: self.viewModel))
                .environmentObject(viewModel)
                .environmentObject(MusicManager(viewModel: viewModel)!)
        )
        
        adjustWindowPosition()
        
        window.orderFrontRegardless()
    }
    
    @objc func adjustWindowPosition() {
        if !NSScreen.screens.contains(where: {$0.localizedName == viewModel.selectedScreen}) {
            viewModel.selectedScreen = NSScreen.main?.localizedName ?? "Unknown Screen"
        }
        
        let selectedScreen = NSScreen.screens.first(where: {$0.localizedName == viewModel.selectedScreen})
        closedNotchSize = setNotchSize(screen: selectedScreen?.localizedName)
        
        if let screenFrame = selectedScreen {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
             DispatchQueue.main.async {[weak self] in
                 let origin = screenFrame.frame.origin.applying(
                     CGAffineTransform(
                         translationX: (screenFrame.frame.width / 2) - self!.window.frame.width / 2,
                         y: screenFrame.frame.height - self!.window.frame.height
                     )
                 )
                
                 self!.window.setFrameOrigin(origin)
                 self!.window.alphaValue = 1
            }
        }
    }
}
