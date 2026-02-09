//
//  DeveloperView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 22/03/25.
//

import SwiftUI

struct DeveloperView: View {
    @EnvironmentObject var viewModel: NotchViewModel
    
    var body: some View {
        VStack {
            Form {
                Button("Open notch") { viewModel.open() }
                Button("Close notch") { viewModel.close() }
                Button("Restart hello") { viewModel.restartHello() }
                Button("Check for updates") { }
                    .disabled(true)
            }
            .formStyle(.grouped)
        }
        .environmentObject(viewModel)
        .padding([.horizontal], 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    DeveloperView()
        .environmentObject(NotchViewModel())
}
