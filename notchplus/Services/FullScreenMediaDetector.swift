//
//  FullScreenMediaDetector.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 19/10/24.
//

import SwiftUI
import CoreAudio
import Cocoa
import Accessibility
import MacroVisionKit
import Defaults

class FullScreenMediaDetector: ObservableObject {
    static let shared = FullScreenMediaDetector()
    let detector: MacroVisionKit
    let musicManager = MusicManager.shared
    
    @Published var currentAppInFullScreen: Bool = false {
        didSet {
            self.objectWillChange.send()
        }
    }
    var nowPlaying: NowPlaying = .init()
    
    
    func isAppFullScreen(_ app: NSRunningApplication) -> Bool {
        let fullscreenApps = detector.detectFullscreenApps(debug: false)
        return fullscreenApps.contains {
            guard $0.bundleIdentifier != "com.apple.finder" else { return false }
            let isSame = $0.bundleIdentifier == app.bundleIdentifier
            if isSame {
                Logger.log("Fullscreen: \(String(describing: $0.debugDescription))", type: .debug)
            }
            return isSame
        }
    }
    
    func checkFullScreenStatus() {
        DispatchQueue.main.async {
            if let frontMostApp = NSWorkspace.shared.frontmostApplication {
                let sameAppAsNowPlaying = !Defaults[.hideOnFullscreen] ? frontMostApp.bundleIdentifier == self.musicManager.bundleIdentifier : true
                
                Logger.log(Defaults[.hideOnFullscreen] ? "Fullscreen media detection is active." : "", type: .debug)
                Logger.log("Now playing app: \(String(describing: self.musicManager.bundleIdentifier))", type: .debug)
                
                self.currentAppInFullScreen = self.isAppFullScreen(frontMostApp) && sameAppAsNowPlaying
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
            (NSWorkspace.didActivateApplicationNotification, #selector(applicationDidChangeScreenMode(_:))),
            (NSWorkspace.didDeactivateApplicationNotification, #selector(applicationDidChangeScreenMode(_:))),
            (NSApplication.didBecomeActiveNotification, #selector(applicationDidChangeScreenMode(_:))),
            (NSApplication.didResignActiveNotification, #selector(applicationDidChangeScreenMode(_:)))
        ]
        
        for (name, selector) in notificaton {
            notificationCenter.addObserver(self, selector: selector, name: name, object: nil)
        }
    }
    
    init() {
        self.detector = MacroVisionKit.shared
        detector.configuration.includeSystemApps = true
        setupNotificationObservers()
    }
    
    
}
