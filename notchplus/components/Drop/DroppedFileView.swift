//
//  DroppedFileView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/11/24.
//

import SwiftUI

//struct DroppedFileView: View {
//    @EnvironmentObject var viewModel: NotchViewModel
//    
//    var files: [Color] = [.red, .blue, .yellow]
//    @State var offset = CGSize.zero
//    
//    
//    var body: some View {
//        GeometryReader { geo in
//            ZStack {
//                ForEach(0..<self.files.count, id: \.self) { file in
//                    DroppedFile(geo: geo, files: files, file: file)
//                }
//            }
//        }
//        .animation(.spring())
//    }
//}

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
//                    .overlay {
//                        Text(item.fileName)
//                            .multilineTextAlignment(.center)
//                            .font(.footnote)
//                            .foregroundStyle(.white)
//                            .lineLimit(1)
//                            .allowsTightening(true)
//                            .frame(maxHeight: .infinity, alignment: .centerFirstTextBaseline)
//                            .padding()
//                    }
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

//#Preview {
//    DroppedFileView()
//        .environmentObject(NotchViewModel())
////        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .frame(width: 300, height: 500)
//}
