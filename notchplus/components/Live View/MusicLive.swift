//
//  MusicLive.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 15/11/24.
//

import SwiftUI
import Defaults

struct MusicLiveActivity: View {
    @EnvironmentObject var viewModel: NotchViewModel
    @EnvironmentObject var musicManager: MusicManager
    @Namespace var albumArtNamespace
    
    @Binding var hoverAnimation: Bool
    @Binding var gestureProgress: CGFloat
    
    var body: some View {
        HStack {
            HStack {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .background(
                        Image(nsImage: musicManager.songArtwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    )
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: viewModel.musicPlayerSizes.image.cornerRadius.closed.inset!))
                    .matchedGeometryEffect(id: "albumArtwork", in: albumArtNamespace)
                    .frame(width: Sizes().size.closed.height! - 12, height: Sizes().size.closed.height! - 12)
            }
            .frame(
                width: Sizes().size.closed.height! - (hoverAnimation ? 0 : 12) + gestureProgress / 2,
                height: Sizes().size.closed.height! - (hoverAnimation ? 0 : 12)
            )
            
            Rectangle()
                .fill(.black)
                .frame(width: viewModel.sizes.size.closed.width! - 20)
            
            HStack {
                Rectangle()
                    .fill(Defaults[.coloredSpectogram] ? Color(nsColor: musicManager.avgColor).gradient : Color.gray.gradient)
                    .mask {
                        AudioSpectrumView(isPlaying: $musicManager.isPlaying)
                            .frame(width: 16, height: 12)
                    }
                
            }
            .frame(
                width: Sizes().size.closed.height! - (hoverAnimation ? 0 : 12) + gestureProgress / 2,
                height: Sizes().size.closed.height! - (hoverAnimation ? 0 : 12),
                alignment: .center
            )
            
        }
        .frame(
            height: Sizes().size.closed.height! + (hoverAnimation ? 8 : 0),
            alignment: .center
        )
    }
}
