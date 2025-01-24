//
//  AboutUs.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 16/12/24.
//

import SwiftUI

struct AboutUsView: View {
    
    var body: some View {
        VStack {
            Form {
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About notchplus")
                        .font(.title2)
                }
            }
        }
        .padding(30)
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
