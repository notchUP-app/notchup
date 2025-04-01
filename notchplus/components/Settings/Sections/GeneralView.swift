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
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Defaults.Toggle("Show menubar icon", key: .menuBarIcon)
                        .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                    LaunchAtLogin.Toggle("Launch at login")
                        .toggleStyle(SwitchToggleStyle(tint: Defaults[.accentColor]))
                } header: {
                    Text("System features")
                        .fontWeight(.semibold)
                }
                
                Section {
                    Picker("Main display", selection: $coordinator.mainScreenName) {
                        ForEach(screens, id: \.self) { screen in
                            Text(screen)
                        }
                    }
                    .onChange(of: NSScreen.screens) { old, new in
                        screens = new.compactMap({ $0.localizedName })
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Display")
                        .fontWeight(.semibold)
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
    GeneralView()
        .environmentObject(NotchViewModel())
}
