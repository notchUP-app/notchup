//
//  GeneralSettings.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 14/11/24.
//

import SwiftUI
import Defaults
import LaunchAtLogin

struct GeneralSettings: View {
    @EnvironmentObject var viewModel: NotchViewModel
    @State var screens: [String] = NSScreen.screens.map { $0.localizedName }
    
    var body: some View {
        Form {
            Section {
                Defaults.Toggle("Show menubar icon", key: .menuBarIcon)
                LaunchAtLogin.Toggle("Launch at login")
                
                Text("Displays")
                    .padding(.top, 10)
                    .font(.title2)
                    .fontWeight(.semibold)
                Picker("", selection: $viewModel.selectedScreen) {
                    ForEach(screens, id: \.self) { screen in
                        Text(screen)
                    }
                }
                .onChange(of: NSScreen.screens) { old, new in
                    screens = new.compactMap({ $0.localizedName })
                }
                .pickerStyle(.menu)
                Spacer()
            } header: {
                Text("General")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
        .tint(Defaults[.accentColor])
        .navigationTitle("General")
//        .frame(width: 400)
        .padding(30)
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        
    }
}
