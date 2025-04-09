//
//  NotchHomeView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 03/11/24.
//

import SwiftUI
import Combine
import Defaults

struct NotchHomeView: View {
    @EnvironmentObject var viewModel: NotchViewModel
    @EnvironmentObject var batteryModel: BatteryStatusViewModel
    @EnvironmentObject var musicManager: MusicManager
    @ObservedObject var coordinator = NotchViewCoordinator.shared
    
    @State private var sliderValue: Double = 0.0
    @State private var dragging: Bool = false
    @State private var timer: AnyCancellable?
    @State private var lastDragged: Date = .distantPast
    @State private var previousBundleIdentifier: String = "com.apple.Music"
    let albumArtNamespace: Namespace.ID
    
    var body: some View {
        if !coordinator.firstLaunch {
            HStack(alignment: .top, spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    if Defaults[.blurredArtwork] {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .background {
                                Image(nsImage:
                                        musicManager.getAlbumArt(
                                            for: "\(musicManager.songTitle)-\(musicManager.songArtist)-\(musicManager.songAlbum)",
                                            size: CoverSize.large
                                        ) ?? defaultImage
                                )
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                            }
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: Defaults[.cornerRadiusScaling] ? viewModel.musicPlayerSizes.image.cornerRadius.opened.inset! : viewModel.musicPlayerSizes.image.cornerRadius.closed.inset!))
                            .scaleEffect(x: 1.3, y: 2.8)
                            .rotationEffect(.degrees(90))
                            .blur(radius: 35)
                            .opacity(min(0.6, 1 - max(musicManager.songArtwork.getBrightness(), 0.3)))
                    }
                    
                    Button {
                        musicManager.openAppMusic()
                    } label: {
                        ZStack (alignment: .bottomTrailing) {
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                                .background(
                                    Image(nsImage:
                                            musicManager.getAlbumArt(
                                                for: "\(musicManager.songTitle)-\(musicManager.songArtist)-\(musicManager.songAlbum)",
                                                size: CoverSize.large
                                            ) ?? defaultImage
                                         )
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                )
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: Defaults[.cornerRadiusScaling] ? viewModel.musicPlayerSizes.image.cornerRadius.opened.inset! : viewModel.musicPlayerSizes.image.cornerRadius.closed.inset!))
                                .matchedGeometryEffect(id: "albumArtwork", in: albumArtNamespace)
                            
                            if viewModel.notchState == .open {
                                AppIcon(for: musicManager.bundleIdentifier)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 30)
                                    .offset(x: 10, y: 10)
                                    .transition(.scale.combined(with: .opacity).animation(.bouncy.delay(0.4)))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                VStack(alignment: .leading) {
                    GeometryReader { geo in
                        VStack(alignment: .leading, spacing: 4) {
                            MarqueeText(musicManager.songTitle, font: .headline, nsFont: .headline, textColor: .white, frameWidth: geo.size.width)
                            MarqueeText(musicManager.songArtist, font: .headline, nsFont: .headline, textColor: .gray, frameWidth: geo.size.width)
                                .fontWeight(.medium)
                            
                            MusicSliderView(
                                sliderValue: $sliderValue,
                                duration: $musicManager.songDuration,
                                dragging: $dragging,
                                lastDragged: $lastDragged,
                                color: musicManager.avgColor
                            ) { newValue in
                                musicManager.seekTrack(to: newValue)
                            }
                            .padding(.top, 5)
                            .frame(height: 36)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.leading, 5)
                    
                    HStack(spacing: 0) {
                        HoverButton(icon: "backward.fill") {
                            musicManager.previousTrack()
                        }
                        HoverButton(icon: musicManager.isPlaying ? "pause.fill" : "play.fill") {
                            musicManager.togglePlayPause()
                        }
                        HoverButton(icon: "forward.fill") {
                            musicManager.nextTrack()
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(viewModel.notchState == .closed ? 0 : 1)
                .blur(radius: viewModel.notchState == .closed ? 20 : 0)
            
                if Defaults[.dropBoxByDefault] {
                    Spacer()
                    NotchDropView()
                }

            }
            .onAppear {
                if coordinator.firstLaunch {
                    viewModel.open()
                }
                sliderValue = musicManager.elapsedTime
                startTimer()
            }
            .onDisappear {
                timer?.cancel()
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [self] _ in
                self.updateSliderValue()
            }
    }
    
    private func updateSliderValue() {
        guard !dragging, musicManager.isPlaying, musicManager.timestampDate > lastDragged else { return }
        
        let currentTime = Date()
        let timeDifference = currentTime.timeIntervalSince(musicManager.timestampDate)
        
        let currentEllapsedTime = musicManager.elapsedTime + (timeDifference * musicManager.playbackRate)
        sliderValue = min(currentEllapsedTime, musicManager.songDuration)
    }
}
