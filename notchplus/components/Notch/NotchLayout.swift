//
//  NotchLayout.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 15/11/24.
//

import SwiftUI
import Defaults

struct NotchLayout: View {
    @EnvironmentObject var viewModel: NotchViewModel
    @EnvironmentObject var musicManager: MusicManager
    @EnvironmentObject var batteryModel: BatteryStatusViewModel
    
    @Binding var hoverAnimation: Bool
    @Binding var gestureProgress: CGFloat
    
    @Namespace var albumArtNamespace

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                if viewModel.firstLaunch {
                    Spacer()
                    HelloAnimation()
                        .frame(width: 200, height: 80)
                        .onAppear(perform: {
                            viewModel.closeHello()
                        })
                        .padding(.top, 40)
                    Spacer()
                }
                else {
                    if viewModel.expandingView.type == .battery && viewModel.expandingView.show && viewModel.notchState == .closed {
                        HStack(spacing: 0) {
                            HStack {
                                Text("Charging")
                                    .font(.subheadline)
                            }
                            
                            Rectangle()
                                .fill(.black)
                                .frame(width: Sizes().size.closed.width! + 5)
                            
                            HStack {
                                BatteryView(
                                    batteryLevel: batteryModel.batteryLevel,
                                    isPluggedIn: batteryModel.isPluggedIn,
                                    batteryWidth: 30
                                )
                            }
                            .frame(width: 76, alignment: .trailing)
                        }
                        .frame(height: Sizes().size.closed.height! + (hoverAnimation ? 8 : 0), alignment: .center)
                    }
                    else if viewModel.sneakPeek.show && Defaults[.inlineHudShow] && (viewModel.sneakPeek.type != .music) && (viewModel.sneakPeek.type != .battery) {
                        InlineHUD(
                            type: $viewModel.sneakPeek.type,
                            value: $viewModel.sneakPeek.value,
                            icon: $viewModel.sneakPeek.icon,
                            hoverAnimation: $hoverAnimation,
                            gestureProgress: $gestureProgress
                        )
                        .transition(.opacity)
                    }
                    else if !viewModel.expandingView.show && viewModel.notchState == .closed && (musicManager.isPlaying || !musicManager.isPlayerIdle) && viewModel.showMusicLiveActivityOnClosed {
                        MusicLiveActivity(
                            hoverAnimation: $hoverAnimation,
                            gestureProgress: $gestureProgress,
                            albumArtNamespace: albumArtNamespace
                        )
                    }
                    else {
                        NotchHeader()
                            .frame(height: Sizes().size.closed.height!)
                            .blur(radius: abs(gestureProgress) > 0.3 ? min(abs(gestureProgress), 8) : 0)
                    }
                    
                    if viewModel.sneakPeek.show && !Defaults[.inlineHudShow] {
                        if (viewModel.sneakPeek.type != .music) && (viewModel.sneakPeek.type != .battery) {
                            SystemEventIndicatorModifier(
                                eventType: $viewModel.sneakPeek.type,
                                icon: $viewModel.sneakPeek.icon,
                                value: $viewModel.sneakPeek.value,
                                sendEventBack: { _ in }
                            )
                            .padding(.bottom, 10)
                            .padding(.leading, 4)
                            .padding(.trailing, 8)
                        } else if viewModel.sneakPeek.type != .battery {
                            if viewModel.notchState == .closed {
                                HStack(alignment: .center) {
                                    Image(systemName: "music.note")
                                    GeometryReader { geometry in
                                        MarqueeText(
                                            musicManager.songTitle + " - " + musicManager.songArtist,
                                            textColor: .gray,
                                            minDuration: 1,
                                            frameWidth: geometry.size.width
                                        )
                                    }
                                }
                                .foregroundStyle(.gray)
                                .padding(.bottom, 10)
                            }
                        }
                    }
                }
            }
            .conditionalModifier((viewModel.sneakPeek.show && (viewModel.sneakPeek.type == .music) && viewModel.notchState == .closed) || (viewModel.sneakPeek.show && (viewModel.sneakPeek.type != .music) && (musicManager.isPlaying || !musicManager.isPlayerIdle ))) {
                view in view.fixedSize()
            }
            .zIndex(2)
            
            ZStack {
                if viewModel.notchState == .open {
                    switch viewModel.currentView {
                    case .home:
                        NotchHomeView(albumArtNamespace: albumArtNamespace)
                    }
                }
            }
            .zIndex(1)
            .allowsHitTesting(viewModel.notchState == .open)
            .blur(radius: abs(gestureProgress) > 0.3 ? min(gestureProgress, 8) : 0)
            
        }
    }
}
