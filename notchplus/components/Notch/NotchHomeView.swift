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
    
    @State private var sliderValue: Double = 0.0
    @State private var dragging: Bool = false
    @State private var timer: AnyCancellable?
    @State private var lastDragged: Date = .distantPast
    @State private var previousBundleIdentifier: String = "com.apple.Music"
    let albumArtNamespace: Namespace.ID
    
    var body: some View {
        if !viewModel.firstLaunch {
            HStack(alignment: .top, spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    if Defaults[.lightingEffect] {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .background(
                                Image(nsImage: musicManager.songArtwork)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            )
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
                                    Image(nsImage: musicManager.songArtwork)
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
            }
            .onAppear {
                viewModel.open()
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

struct CustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var color: Color = .white
    @Binding var dragging: Bool
    @Binding var lastDragged: Date
    var onValueChange: ((Double) -> Void)?
    var thumbSize: CGFloat = 12
    @State private var hovered: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let rangeSpan = range.upperBound - range.lowerBound
            
            let filledTrackWidth = rangeSpan == .zero ? 0 : ((value - range.lowerBound) / rangeSpan) * width
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                Capsule()
                    .fill(color)
                    .frame(width: filledTrackWidth, height: height)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        withAnimation {
                            dragging = true
                        }
                        let newValue = range.lowerBound + Double(gesture.location.x / width) * rangeSpan
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        onValueChange?(value)
                        dragging = false
                        lastDragged = Date()
                    }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    withAnimation {
                        hovered = true
                    }
                case .ended:
                    withAnimation {
                        hovered = false
                    }
                }
            }
        }
        .frame(height: dragging || hovered ? 8 : 5)
    }
}

struct MusicSliderView: View {
    @Binding var sliderValue: Double
    @Binding var duration: Double
    @Binding var dragging: Bool
    @Binding var lastDragged: Date
    
    var color: NSColor
    var onValueChange: ((Double) -> Void)
    
    var body: some View {
        VStack {
            CustomSlider(
                value: $sliderValue,
                range: 0...duration,
                color: Defaults[.sliderColor] == SliderColorEnum.albumArt
                ? Color(nsColor: color)
                : Defaults[.sliderColor] == SliderColorEnum.accent
                ? Defaults[.accentColor] : .white,
                dragging: $dragging,
                lastDragged: $lastDragged,
                onValueChange: onValueChange
            )
            .frame(height: 10, alignment: .center)
            HStack {
                Text(timeString(from: sliderValue))
                Spacer()
                Text(timeString(from: duration))
            }
            .fontWeight(.medium)
            .foregroundColor(.gray)
            .font(.caption)
        }
    }
    
    func timeString(from seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NotchHomeView(
        albumArtNamespace: Namespace().wrappedValue
    )
    .environmentObject(MusicManager(viewModel: NotchViewModel())!)
    .environmentObject(NotchViewModel())
    .environmentObject(BatteryStatusViewModel(viewModel: NotchViewModel()))
}
