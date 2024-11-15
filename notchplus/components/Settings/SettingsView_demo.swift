//
//  SettingsView_demo.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 14/11/24.
//

import SwiftUI

struct SettingsViewDemo: View {
    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape.fill") {
                GeneralSettings()
//                    .toolbar {
//                        Button("Quit app") {
//                            NSApp.terminate(self)
//                        }
//                        .controlSize(.extraLarge)
//                    }
            }
            Tab("Appearance", systemImage: "star.fill") {
                EmptyView()
            }
            Tab("About Us", systemImage: "person.2.fill") {
                EmptyView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    SettingsViewDemo()
}
