//
//  LockScreenManager.swift
//  notchplus
//
//  Created by Assistant on 14/09/25.
//

import Foundation
import AppKit
import Combine
import UserNotifications

class LockScreenManager: ObservableObject {
    static let shared = LockScreenManager()
    
    @Published var isLockScreenActive: Bool = false
    @Published var canShowOnLockScreen: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var lockScreenObserver: NSObjectProtocol?
    
    private init() {
        setupLockScreenDetection()
        checkLockScreenCapabilities()
    }
    
    deinit {
        if let observer = lockScreenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        cancellables.removeAll()
    }
    
    private func setupLockScreenDetection() {
        // Listen for screen lock/unlock events
        lockScreenObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLockScreenActive = true
            Logger.log("Screen locked detected", type: .info)
        }
        
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLockScreenActive = false
            Logger.log("Screen unlocked detected", type: .info)
        }
        
        // Alternative method using screen saver notifications
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstart"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Screen saver started - might indicate lock
            Logger.log("Screen saver started", type: .debug)
        }
        
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstop"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Screen saver stopped - might indicate unlock
            Logger.log("Screen saver stopped", type: .debug)
        }
    }
    
    private func checkLockScreenCapabilities() {
        // Check if we can run on lock screen
        // Note: Direct lock screen app execution is not supported on macOS
        // This is more about preparing for potential future capabilities
        
        if #available(macOS 15.0, *) {
            // macOS 15+ might have enhanced lock screen capabilities
            canShowOnLockScreen = checkForEnhancedLockScreenSupport()
        } else {
            canShowOnLockScreen = false
        }
        
        Logger.log("Lock screen capabilities: \(canShowOnLockScreen)", type: .info)
    }
    
    @available(macOS 15.0, *)
    private func checkForEnhancedLockScreenSupport() -> Bool {
        // Check for system permissions and capabilities
        // This is experimental - actual implementation would need testing
        
        // Check if we have accessibility permissions
        let hasAccessibilityPermissions = AXIsProcessTrusted()
        
        // Check if we can create overlays using proper CGWindowLevel constants
//        let canCreateOverlays = CGWindowLevel.screenSaver != CGWindowLevel.normal
        let canCreateOverlays = true // Placeholder, as actual check is complex
        
        return hasAccessibilityPermissions && canCreateOverlays
    }
    
    // MARK: - Lock Screen Widget Simulation
    
    func createLockScreenOverlay() -> Bool {
        guard canShowOnLockScreen else {
            Logger.log("Cannot create lock screen overlay - insufficient permissions", type: .warning)
            return false
        }
        
        // This is a conceptual implementation
        // Actual lock screen functionality would require:
        // 1. System-level permissions
        // 2. Potentially running as a system service
        // 3. Special entitlements from Apple
        
        Logger.log("Lock screen overlay creation attempted", type: .info)
        return false // Not actually implemented due to system limitations
    }
    
    // MARK: - Alternative Approaches
    
    func setupMenuBarPersistence() {
        // Ensure the app stays in menu bar even when screen is locked
        // This is the closest we can get to "lock screen" functionality
        
        if NSApplication.shared.delegate is NSObject {
            // Keep the app running in background
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    func createNotificationBasedUpdates() {
        // Use notifications to show music updates even when locked
        // This provides some lock screen-like functionality
        
        MusicManager.shared.$songTitle
            .combineLatest(MusicManager.shared.$songArtist, MusicManager.shared.$isPlaying)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] title, artist, isPlaying in
                if self?.isLockScreenActive == true && isPlaying {
                    self?.sendMusicNotification(title: title, artist: artist)
                }
            }
            .store(in: &cancellables)
    }
    
    private func sendMusicNotification(title: String, artist: String) {
        let content = UNMutableNotificationContent()
        content.title = "Now Playing"
        content.body = "\(title) - \(artist)"
        content.sound = nil // Silent notification
        
        let request = UNNotificationRequest(
            identifier: "music-update-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.log("Failed to send music notification: \(error)", type: .error)
            }
        }
    }
}

// MARK: - Lock Screen Detection Extensions

extension NSWorkspace {
    var isScreenLocked: Bool {
        // Check if screen is locked by examining running processes
        let task = Process()
        task.launchPath = "/usr/bin/python3"
        task.arguments = ["-c", """
            import Quartz
            d = Quartz.CGSessionCopyCurrentDictionary()
            print(d.get('CGSSessionScreenIsLocked', 0))
        """]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return output == "1"
        } catch {
            Logger.log("Failed to check screen lock status: \(error)", type: .error)
            return false
        }
    }
}
