//
//  NotchDropView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 04/11/24.
//

import SwiftUI
import UniformTypeIdentifiers

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
        .onDrop(of: [UTType.fileURL.identifier, UTType.data.identifier], isTargeted: $viewModel.dropZoneTargeting) { providers in
            viewModel.dropEvent = true
            Task {
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
                GeometryReader { geometry in
                    ZStack(alignment: .topTrailing) {
                        ForEach(trayDropModel.items) { item in
                            DroppedFile(geo: geometry, item: item)
                        }
                    }
                    // TODO: DRAG ALL FILES AT ONCE
//                    .onDrag {
//                        let itemProviders = trayDropModel.items.map { item in
//                            NSItemProvider(contentsOf: item.storageURL) ?? NSItemProvider()
//                        }
//                        
//                        return NSItemProvider(object: itemProviders as! NSArray)
//                    }
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
