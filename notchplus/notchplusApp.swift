//
//  notchplusApp.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import SwiftUI
import Sparkle

@main
struct notchplusApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        Settings {
            SettingsView().environmentObject(appDelegate.viewModel)
        }
    }
}

