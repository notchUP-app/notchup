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
    
    var shouldShowBatteryExpandedView: Bool {
        viewModel.expandingView.show && viewModel.notchState == .closed && viewModel.expandingView.type == .battery
    }
    var shouldShowMusicLiveExpandedView: Bool {
        !viewModel.expandingView.show && viewModel.notchState == .closed && (musicManager.isPlaying || !musicManager.isPlayerIdle) && viewModel.showMusicLiveActivityOnClosed
    }

    var body: some View {
        ZStack {
            Layout()
        }
    }
    
    @ViewBuilder
    private func Layout() -> some View {
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
                    if shouldShowBatteryExpandedView {
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
                    else if shouldShowMusicLiveExpandedView {
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
                }
            }
            .zIndex(2)
            
            ZStack {
                if viewModel.notchState == .open {
                    switch viewModel.coordinator.currentView {
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
