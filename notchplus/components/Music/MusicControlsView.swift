//
//  MusicControlsView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 11/04/25.
//

import SwiftUI

struct MusicControlsView: View {
    @ObservedObject var musicManager = MusicManager.shared
    @State private var sliderValue: Double = 0
    @State private var dragging: Bool = false
    @State private var lastDragged: Date = .distantPast
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geo in
                VStack(alignment: .leading, spacing: 4) {
                    songInfo(width: geo.size.width)
                    musicSlider
                }
            }
            .padding(.top, 10)
            .padding(.leading, 5)
            
            playbackControls
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minWidth: 180)
    }
    
    private func songInfo(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MarqueeText(
                $musicManager.songTitle,
                font: .headline,
                nsFont: .headline,
                textColor: .white,
                frameWidth: width
            )
            MarqueeText(
                $musicManager.songArtist,
                font: .headline,
                nsFont: .headline,
                textColor: .gray,
                frameWidth: width
            )
            .fontWeight(.medium)
        }
    }
    
    private var musicSlider: some View {
        TimelineView(.animation(minimumInterval: musicManager.playbackRate > 0 ? 0.1 : nil)) { timeline in
            MusicSliderView(
                sliderValue: $sliderValue,
                duration: $musicManager.songDuration,
                dragging: $dragging,
                lastDragged: $lastDragged,
                color: musicManager.avgColor,
                currentDate: timeline.date,
                lastUpdated: musicManager.lastUpdated,
                ignoreLastUpdated: musicManager.ignoreLastUpdated,
                timestampDate: musicManager.timestampDate,
                elapsedTime: musicManager.elapsedTime,
                playbackRate: musicManager.playbackRate,
                isPlaying: musicManager.isPlaying
            ) { newValue in
                MusicManager.shared.seek(to: newValue)
            }
            .padding(.top, 5)
            .frame(height: 36)
        }
    }
    
    private var playbackControls: some View {
        HStack(spacing: 8) {
            HoverButton(icon: "backward.fill") {
                MusicManager.shared.previous()
            }
            HoverButton(icon: musicManager.isPlaying ? "pause.fill" : "play.fill") {
                MusicManager.shared.togglePlay()
            }
            HoverButton(icon: "forward.fill") {
                MusicManager.shared.next()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MusicControlsView()
        .frame(width: 300, height: 100)
}
