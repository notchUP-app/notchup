//
//  AboutUs.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 16/12/24.
//

import SwiftUI
import Defaults

struct AboutView: View {
    var body: some View {
        VStack {
            Form {
                Section {
                    HStack {
                        Text("Release")
                        Spacer()
                        Text("Beta internal build")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Version info")
                }
                
                HStack {
                    Spacer()
                    Button("Check for updates") {}
                        .disabled(true)
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
    AboutView()
}
