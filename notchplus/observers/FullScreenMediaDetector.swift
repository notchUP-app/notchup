//
//  FullScreenMediaDetector.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 19/10/24.
//

import SwiftUI
import CoreAudio

class FullScreenMediaDetector: ObservableObject {
    
    @Published var currentAppInFullScreen: Bool = false {
        didSet {
            self.objectWillChange.send()
        }
    }
    
    var nowPlaying: NowPlaying = .init()
    
    private func logFullScreenApp(_ app: NSRunningApplication) {
        NSLog("Current app in full screen: \(currentAppInFullScreen)")
        NSLog("App name: \(app.localizedName ?? "Unknown")")
    }
    
    func isAppFullScreen(_ app: NSRunningApplication) -> Bool {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return false }
        
        let appWindows = windows.filter { ($0[kCGWindowBounds as String] as? Int32) == app.processIdentifier }
        
        return appWindows.contains { window in
            guard let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let isOnScreen = window[kCGWindowIsOnscreen as String] as? Bool,
                  isOnScreen else {
                return false
            }
            
            let windowFrame = CGRect(x: bounds["X"] ?? 0, y: bounds["Y"] ?? 0, width: bounds["width"] ?? 0, height: bounds["height"] ?? 0)
            
            return NSScreen.screens.contains { screen in
                let isFullScreen = windowFrame.equalTo(screen.frame)
                let isSafariFullScreen = windowFrame.size.width == screen.frame.size.width
                
                return isFullScreen || app.localizedName == "Safari" && isSafariFullScreen
            }
        }
    }
    
    func checkFullScreenStatus() {
        DispatchQueue.main.async {
            if let frontMostApp = NSWorkspace.shared.frontmostApplication {
                self.currentAppInFullScreen = self.isAppFullScreen(frontMostApp) && frontMostApp.bundleIdentifier == self.nowPlaying.appBundleIdentifier
                self.logFullScreenApp(frontMostApp)
            }
        }
    }
    
    @objc func activeSpaceDidChange(_ notification: Notification) {
        checkFullScreenStatus()
    }
    
    @objc func applicationDidChangeScreenMode(_ notification: Notification) {
        checkFullScreenStatus()
    }
    
    private func setupNotificationObservers() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        let notificaton: [(Notification.Name, Selector)] = [
            (NSWorkspace.activeSpaceDidChangeNotification, #selector(activeSpaceDidChange(_:))),
            (NSApplication.didChangeScreenParametersNotification, #selector(applicationDidChangeScreenMode(_:))),
            (NSWorkspace.didActivateApplicationNotification, #selector(applicationDidChangeScreenMode(_:)))
        ]
        
        for (name, selector) in notificaton {
            notificationCenter.addObserver(self, selector: selector, name: name, object: nil)
        }
    }
    
    init() {
        setupNotificationObservers()
    }
    
    
}
