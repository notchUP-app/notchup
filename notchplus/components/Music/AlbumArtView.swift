//
//  AlbumArtView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 11/04/25.
//

import SwiftUI
import Defaults

struct AlbumArtView: View {
    @ObservedObject var musicManager = MusicManager.shared
    @ObservedObject var viewModel: NotchViewModel
    let albumArtNamespace: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if Defaults[.blurredArtwork] {
                albumArtBackground
            }
            albumArtButton
        }
    }
    
    private var albumArtBackground: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .background(
                Image(nsImage: musicManager.songArtwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
            .clipped()
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Defaults[.cornerRadiusScaling]
                    ? MusicPlayerImageSizes.cornerRadiusInset.opened
                    : MusicPlayerImageSizes.cornerRadiusInset.closed
                )
            )
            .scaleEffect(x: 1.3, y: 2.8)
            .rotationEffect(.degrees(92))
            .blur(radius: 35)
            .opacity(min(0.6, 1 - max(musicManager.songArtwork.getBrightness(), 0.3)))
    }
    
    private var albumArtButton: some View {
        Button {
            musicManager.openAppMusic()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                albumArtImage
                appIconOverlay
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(musicManager.isPlaying ? 1 : 0.95)
        .scaleEffect(musicManager.isPlaying ? 1 : 0.95)
    }
    
    private var albumArtImage: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .background(
                Image(nsImage: musicManager.songArtwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: musicManager.isFlipping)
            )
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: Defaults[.cornerRadiusScaling] ? MusicPlayerImageSizes.cornerRadiusInset.opened : MusicPlayerImageSizes.cornerRadiusInset.closed))
            .matchedGeometryEffect(id: "albumArtwork", in: albumArtNamespace)
    }
    
    @ViewBuilder
    private var appIconOverlay: some View {
        if viewModel.notchState == .open && !musicManager.usingAppIconForArtwork {
            AppIcon(for: musicManager.bundleIdentifier ?? "com.apple.Music")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 30, height: 30)
                .offset(x: 10, y: 10)
                .transition(.scale.combined(with: .opacity).animation(.bouncy.delay(0.3)))
        }
    }
}
