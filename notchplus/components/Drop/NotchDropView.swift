//
//  NotchDropView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 04/11/24.
//

import SwiftUI

struct NotchDropView: View {
    @EnvironmentObject var viewModel: NotchViewModel
    @StateObject var trayDropModel = TrayDrop.shared
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: Sizes().cornerRadius.opened.inset! - 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundStyle(.white.opacity(0.2))
                .overlay {
                    itemGroup.padding()
                }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(viewModel.animation, value: trayDropModel.items)
        .animation(viewModel.animation, value: trayDropModel.isLoading)
        .onDrop(of: [.data], isTargeted: $viewModel.dropZoneTargeting) { providers in
            viewModel.dropEvent = true
            DispatchQueue.global().async {
                trayDropModel.load(providers)
            }
            
            return true
        }
    }
    
    var itemGroup: some View {
        Group {
            if trayDropModel.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray.and.arrow.up")
                        .symbolVariant(.fill)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white, .gray)
                        .imageScale(.large)
                    
                    Text("Drop files here")
                        .foregroundStyle(.gray)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
            } else {
                HStack(spacing: viewModel.spacing) {
                    Text("Hello")
                    Text("World")
                }
                .padding(viewModel.spacing)
               
            }
        }
    }

}

#Preview {
    NotchDropView()
        .environmentObject(NotchViewModel())
}
