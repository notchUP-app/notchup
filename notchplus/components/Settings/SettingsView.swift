//
//  SettingsView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 18/10/24.
//

import SwiftUI
import Sparkle

struct SettingsView: View {
    
    @EnvironmentObject var viewModel: NotchViewModel
    @ObservedObject var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
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
            
            Button(action: {
                self.updater.checkForUpdates()
            }) {
                Text("Check for updates")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
            }
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
            
        }
        .frame(width: 200, height: 200)
        .environmentObject(viewModel)
    }
}
