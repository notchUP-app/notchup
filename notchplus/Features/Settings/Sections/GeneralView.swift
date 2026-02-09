//
//  GeneralSettings.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 14/11/24.
//

import SwiftUI
import Defaults
import LaunchAtLogin

struct GeneralView: View {
    @EnvironmentObject var viewModel: NotchViewModel
    @State var screens: [String] = NSScreen.screens.map { $0.localizedName }
    @ObservedObject var coordinator = NotchViewCoordinator.shared
    @ObservedObject private var lockScreenManager = LockScreenManager.shared
    
    @Default(.showOnAllDisplays) var showOnAllDisplays
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Defaults.Toggle("Show menubar icon", key: .menuBarIcon)
                        .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                        .disabled(true)
                    LaunchAtLogin.Toggle("Launch at login")
                        .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                    Defaults.Toggle("Hide on fullscreen", key: .hideOnFullscreen)
                        .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                } header: {
                    Text("System features")
                        .fontWeight(.semibold)
                }
                
                Section {
                    Defaults.Toggle("Show on all displays", key: .showOnAllDisplays)
                        .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                        .onChange(of: showOnAllDisplays) {
                            NotificationCenter.default.post(name: Notification.Name.showOnAllDisplaysChanged, object: nil)
                        }
                    
                    if !showOnAllDisplays {
                        Picker("Main display", selection: $coordinator.mainScreenName) {
                            ForEach(screens, id: \.self) { screen in
                                Text(screen)
                            }
                        }
                        .onChange(of: NSScreen.screens) { old, new in
                            screens = new.compactMap({ $0.localizedName })
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Display")
                        .fontWeight(.semibold)
                }
                
                Section {
                    Toggle("Enable lock screen notifications", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                        .disabled(!lockScreenManager.canShowOnLockScreen)
                    
                    if !lockScreenManager.canShowOnLockScreen {
                        Button("Request Lock Screen Permissions") {
                            requestLockScreenPermissions()
                        }
                    }
                } header: {
                    Text("Lock Screen")
                        .fontWeight(.semibold)
                } footer: {
                    Text("Show music notifications when the screen is locked. Full app functionality on lock screen is not supported by macOS.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Defaults.Toggle("Enable haptic feedback", key: .enableHaptics)
                        .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                    Defaults.Toggle("Open notch on hover", key: .openNotchOnHover)
                        .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                    
                    HStack {
                        Text("Hover duration")
                        Spacer()
                        Slider(value: Binding(
                            get: { Defaults[.minimumHoverDuration] },
                            set: { Defaults[.minimumHoverDuration] = $0 }
                        ), in: 0.1...2.0, step: 0.1)
                        .frame(width: 100)
                        Text("\(Defaults[.minimumHoverDuration], specifier: "%.1f")s")
                            .frame(width: 40)
                    }
                } header: {
                    Text("Interaction")
                        .fontWeight(.semibold)
                }
            }
            .formStyle(.grouped)
            .tint(Defaults[.accentColor])
        }
        .padding([.horizontal], 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func requestLockScreenPermissions() {
        let alert = NSAlert()
        alert.messageText = "Lock Screen Permissions Required"
        alert.informativeText = "To enable lock screen functionality, NotchPlus needs accessibility permissions. This will open System Preferences where you can grant these permissions."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    GeneralView()
        .environmentObject(NotchViewModel())
}
