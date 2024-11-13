//
//  DroppedFileView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/11/24.
//

import SwiftUI

struct DroppedFile: View {
    let geo: GeometryProxy
    let item: TrayDrop.DropItem
    
    @EnvironmentObject var viewModel: NotchViewModel
    @State var trayDropModel = TrayDrop.shared
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.clear)
                    .aspectRatio(1, contentMode: .fit)
                    .background {
                        Image(nsImage: item.workspacePreviewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .position(
                        x: geo.size.width / 2,
                        // TODO: implement item index on position height { + (10 * trayDropModel.items.index(of: item)) }
                        y: (geo.size.height / 2)
                    )
            }
            .rotationEffect(
                trayDropModel.items.count % 2 == 0
                ? .degrees(-0.2 * Double(arc4random_uniform(15) + 1))
                : .degrees(0.2 * Double(arc4random_uniform(15) + 1))
            )
            .onDrag {
                trayDropModel.items.remove(item)
                return NSItemProvider(contentsOf: item.storageURL) ?? .init()
            }
            .frame(width: 64, height: 64)
        }
    }
}
