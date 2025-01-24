//
//  notchplusApp.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import SwiftUI
import Sparkle
import Defaults
import Combine

@main
struct notchplusApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    @Default(.menuBarIcon) var showMenuBarIcon
    var body: some Scene {
        Settings {
            SettingsWindow()
                .environmentObject(appDelegate.viewModel)
        }
        
        MenuBarExtra("notchplus", systemImage: "sparkle", isInserted: $showMenuBarIcon) {
            SettingsLink(label: {
                Text("Settings")
            })
            .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
            
            Divider()
            
            Button("Quit", role: .destructive) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut(KeyEquivalent("Q"), modifiers: .command)
            
            Divider()
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                
        }
        
    }
    
}

