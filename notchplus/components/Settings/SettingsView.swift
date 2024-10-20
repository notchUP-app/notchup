//
//  SettingsView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 18/10/24.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var viewModel: NotchViewModel
    
    var body: some View {
        List {
            Button(action: {
                viewModel.open()
            }) {
                Text("Open notch")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
            }
            
            Button(action: {
                viewModel.close()
            }) {
                Text("Close notch")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
            }
            
            Button(action: {
                viewModel.restartHello()
            }) {
                Text("Restart hello")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
            }
        }
        .frame(width: 200, height: 200)
        .environmentObject(viewModel)
    }
}

#Preview {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    SettingsView().environmentObject(appDelegate.viewModel)
}
