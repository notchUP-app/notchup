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
    
    @Default(.menuBarIcon) var showMenuBarIcon
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        Settings {
            SettingsView().environmentObject(appDelegate.viewModel)
        }
        
        MenuBarExtra("notchplus", systemImage: "sparkle", isInserted: $showMenuBarIcon) {
            SettingsLink(label: {
                Text("Settings")
            })
            .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
            
            Divider()
            
            Button("Restart") {}
            Button("Quit", role: .destructive) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut(KeyEquivalent("Q"), modifiers: .command)
        }
        
        
    }
}

