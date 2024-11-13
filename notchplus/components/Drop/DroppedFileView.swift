//
//  DroppedFileView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/11/24.
//

import SwiftUI

struct DroppedFileView: View {
    @EnvironmentObject var viewModel: NotchViewModel
    
    var files: [Color] = [.red, .blue, .yellow]
    @State var offset = CGSize.zero
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<self.files.count, id: \.self) { file in
                    DroppedFile(geo: geo, files: files, file: file)
                }
            }
        }
        .animation(.spring())
    }
}

struct DroppedFile: View {
    //    let item: TrayDrop.DropItem
    @EnvironmentObject var viewModel: NotchViewModel
    
    var geo: GeometryProxy
    let files: [Color]
    let file: Int
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(files[file])
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Text("file")
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .allowsTightening(true)
                            .frame(maxHeight: .infinity, alignment: .centerFirstTextBaseline)
                            .padding()
                    }
                    .position(x: geo.size.width / 2, y: (geo.size.height / 2) + (10 * CGFloat(file)))
            }
            .rotationEffect(file % 2 == 0 ? .degrees(-0.2 * Double(arc4random_uniform(15) + 1)) : .degrees(0.2 * Double(arc4random_uniform(15) + 1)))
        }
    }
}

#Preview {
    DroppedFileView()
        .environmentObject(NotchViewModel())
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(width: 300, height: 500)
}
