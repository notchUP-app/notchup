//
//  GeneralSettings.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 14/11/24.
//

import SwiftUI
import Defaults
import LaunchAtLogin

@ViewBuilder
func GeneralSettings() -> some View {
    Form {
        Section {
            Defaults.Toggle("Show menubar icon", key: .menuBarIcon)
            LaunchAtLogin.Toggle("Launch at login")
        } header: {
            Text("General")
        }
        
        Section {
            
        } header: {
            Text("Non-notch displays")
        }
    }
    .tint(Defaults[.accentColor])
    .navigationTitle("General")
}
