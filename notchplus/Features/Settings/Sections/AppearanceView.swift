//
//  AppearanceView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 19/03/25.
//

import SwiftUI
import Defaults

struct AppearanceView: View {
    @State private var selection = Defaults[.accentColor]
    @State private var settingsButtonActionSelection = Defaults[.settingsButtonAction]
    @State private var selectedTheme = Defaults[.appTheme]
    
    @Default(.matchSystemAccent) private var matchSystemAccent
    @Default(.settingsButtonAction) private var settingsButtonAction
    @Default(.appTheme) private var appTheme
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Picker("App Theme", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases.filter { $0.isAvailable }) { theme in
                            VStack(alignment: .leading) {
                                Text(theme.rawValue)
                                Text(theme.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedTheme) { oldValue, newValue in 
                        Defaults[.appTheme] = newValue 
                    }
                } header: {
                    Text("Theme")
                } footer: {
                    if !AppTheme.liquidGlass.isAvailable {
                        Text("Liquid Glass theme requires macOS 26 or later")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Section {
                    Defaults.Toggle("Match system accent color", key: .matchSystemAccent)
                    if !matchSystemAccent {
                        ColorPicker("Accent color", selection: $selection)
                            .onChange(of: selection) { oldValue, newValue in Defaults[.accentColor] = newValue }
                    }
                } header: {
                    Text("Colors")
                }
                
                Section {
                    Defaults.Toggle("Enable background cover blur", key: .blurredArtwork)
                    Defaults.Toggle("Enable spectogram color", key: .coloredSpectogram)
                } header: {
                    Text("Media")
                }
                
                Section {
                    Defaults.Toggle("Show battery indicator", key: .showBattery)
                    Defaults.Toggle("Show settings button", key: .settingsIconInNotch)
                    Picker("Settings button opens", selection: $settingsButtonActionSelection) {
                        ForEach(NotchSettingsAction.allCases, id: \.self) { button in
                            Text(button.rawValue)
                        }
                    }
                    .onChange(of: settingsButtonActionSelection) { oldValue, newValue in Defaults[.settingsButtonAction] = newValue }
                } header: {
                    Text("Header")
                }
            }
            .formStyle(.grouped)
            .tint(Defaults[.accentColor])
        }
        .padding([.horizontal], 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    AppearanceView()
}
