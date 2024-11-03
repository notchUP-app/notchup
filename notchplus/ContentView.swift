//
//  ContentView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import SwiftUI
import Defaults

struct ContentView: View {
    let onHover: () -> Void
    
    @EnvironmentObject var viewModel: NotchViewModel
    @EnvironmentObject var musicManager: MusicManager
    
    @StateObject var batteryModel: BatteryStatusViewModel
    
    @State private var hoverStartTime: Date?
    @State private var hoverTimer: Timer?
    @State private var hoverAnimation: Bool = false
    @State private var gestureProgress: CGFloat = .zero
    @State private var haptics: Bool = false
    
    @Namespace var albumArtNamespace
    
    var body: some View {
        ZStack {
            NotchLayout()
                .padding(.horizontal, viewModel.notchState == .open ? Defaults[.cornerRadiusScaling] ? (viewModel.sizes.cornerRadius.opened.inset! - 5) : (viewModel.sizes.cornerRadius.closed.inset! - 5) : 12)
                .padding([.horizontal, .bottom], viewModel.notchState == .open ? 12 : 0)
                .frame(
                    maxWidth: (((musicManager.isPlaying || !musicManager.isPlayerIdle) && viewModel.notchState == .closed && viewModel.showMusicLiveActivityOnClosed) || (viewModel.expandingView.show && (viewModel.expandingView.type == .battery)) || Defaults[.inlineHUD]) ? nil : viewModel.notchSize.width + ((hoverAnimation || (viewModel.notchState == .closed)) ? 20 : 0) + gestureProgress,
                    maxHeight: ((viewModel.sneakPeek.show && viewModel.sneakPeek.type != .music) || (viewModel.sneakPeek.show && viewModel.sneakPeek.type == .music && viewModel.notchState == .closed)) ? nil : viewModel.notchSize.height + (hoverAnimation ? 8 : 0) + gestureProgress / 3,
                    alignment: .top
                )
                .background(.black)
                .mask {
                    NotchShape(cornerRadius: ((viewModel.notchState == .open) && Defaults[.cornerRadiusScaling]) ? viewModel.sizes.cornerRadius.opened.inset : viewModel.sizes.cornerRadius.closed.inset)
                }
                .frame(
                    width: viewModel.notchState == .closed ? (((musicManager.isPlaying || !musicManager.isPlayerIdle) && viewModel.showMusicLiveActivityOnClosed) || (viewModel.expandingView.show && (viewModel.expandingView.type == .battery)) || (Defaults[.inlineHUD] && viewModel.sneakPeek.type != .music)) ? nil : Sizes().size.closed.width! + (hoverAnimation ? 20 : 0) + gestureProgress : nil,
                    height: viewModel.notchState == .closed ? Sizes().size.closed.height! + (hoverAnimation ? 8 : 0) + gestureProgress / 3 : nil,
                    alignment: .top
                )
                .conditionalModifier(Defaults[.openNotchOnHover]) { view in
                    view.onHover { hovering in
                        if hovering {
                            withAnimation(.bouncy) {
                                hoverAnimation = true
                            }
                            
                            if (viewModel.notchState == .closed) && Defaults[.enableHaptics] {
                                haptics.toggle()
                            }
                            
                            if viewModel.sneakPeek.show {
                                return
                            }
                            
                            startHoverTimer()
                        } else {
                            withAnimation(.bouncy) {
                                hoverAnimation = false
                            }
                            
                            cancelHoverTimer()
                            
                            if viewModel.notchState == .open {
                                viewModel.close()
                            }
                        }
                    }
                }
                .conditionalModifier(!Defaults[.openNotchOnHover]) { view in
                    view
                        .onHover { hovering in
                            if hovering {
                                withAnimation(viewModel.animation) {
                                    hoverAnimation = true
                                }
                            } else {
                                withAnimation(viewModel.animation) {
                                    hoverAnimation = false
                                }
                            
                                if viewModel.notchState == .open {
                                    viewModel.close()
                                }
                            }
                        }
                        .onTapGesture {
                            if (viewModel.notchState == .closed) && Defaults[.enableHaptics] {
                                haptics.toggle()
                            }
                            doOpen()
                        }
                        .conditionalModifier(Defaults[.enableGestures]) { view in
                            view.panGesture(direction: .down) { translation, phase in
                                guard viewModel.notchState == .closed else { return }
                                
                                withAnimation(.smooth) {
                                    gestureProgress = (translation / Defaults[.gestureSensitivity]) * 20
                                }
                                
                                if phase == .ended {
                                    withAnimation(.smooth) {
                                        gestureProgress = .zero
                                    }
                                }
                                
                                if translation > Defaults[.gestureSensitivity] {
                                    if Defaults[.enableHaptics] {
                                        haptics.toggle()
                                    }
                                    
                                    withAnimation(.smooth) {
                                        gestureProgress = .zero
                                    }
                                    
                                    doOpen()
                                }
                            }
                        }
                    
                }
                .conditionalModifier(Defaults[.closeGestureEnabled] && Defaults[.enableGestures]) { view in
                    view.panGesture(direction: .up) { translation, phase in
                        if viewModel.notchState == .open {
                            withAnimation(.smooth) {
                                gestureProgress = (translation / Defaults[.gestureSensitivity]) * -20
                            }
                            
                            if phase == .ended {
                                withAnimation(.smooth) {
                                    gestureProgress = .zero
                                }
                            }
                            
                            if translation > Defaults[.gestureSensitivity] {
                                withAnimation(.smooth) {
                                    gestureProgress = .zero
                                    hoverAnimation = false
                                }
                                
                                viewModel.close()
                                
                                if (viewModel.notchState == .closed) && Defaults[.enableHaptics] {
                                    haptics.toggle()
                                }
                            }
                        }
                    }
                }
                .onAppear(perform: {
                    // the notch view already starts shaped after 0.1s
                    // change to `DispatchQueue.main.async { ... }` to make it start on open
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation(viewModel.animation) {
                            if viewModel.firstLaunch {
                                doOpen()
                            }
                        }
                    }
                })
                .sensoryFeedback(.alignment, trigger: haptics)
                .contextMenu {
                    SettingsLink(label: {
                        Text("Settings")
                    })
                    .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
                
                    Button("Edit") {
                        let dynamicNotch = DynamicNotch(content: EditPanelView())
                        dynamicNotch.toggle()
                    }
#if DEBUG
                    .disabled(false)
#else
                    .disabled(true)
#endif
                    .keyboardShortcut(KeyEquivalent("E"), modifiers: .command)
                }
        }
        .frame(maxWidth: Sizes().size.opened.width! + 40, maxHeight: Sizes().size.opened.height! + 20, alignment: .top)
        .shadow(color: (viewModel.notchState == .open && Defaults[.enableShadow] ? .black.opacity(0.6) : .clear), radius: Defaults[.cornerRadiusScaling] ? 10 : 5)
        .environmentObject(viewModel)
        .environmentObject(musicManager)
        .environmentObject(batteryModel)
        
    }
    
    @ViewBuilder
    func NotchLayout() -> some View {
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
                    else if viewModel.sneakPeek.show && Defaults[.inlineHUD] && (viewModel.sneakPeek.type != .music) && (viewModel.sneakPeek.type != .battery) {
                        // not implemented
                    }
                    else if !viewModel.expandingView.show && viewModel.notchState == .closed && (musicManager.isPlaying || !musicManager.isPlayerIdle) && viewModel.showMusicLiveActivityOnClosed {
                        MusicLiveActivity()
                    }
                    else {
                        NotchHeader()
                            .frame(height: Sizes().size.closed.height!)
                            .blur(radius: abs(gestureProgress) > 0.3 ? min(abs(gestureProgress), 8) : 0)
                    }
                    
                    if viewModel.sneakPeek.show && Defaults[.inlineHUD] {
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
                                            Text("MarqueeText")
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
                            Text("Home")
                    }
                }
            }
            .zIndex(1)
            .allowsHitTesting(viewModel.notchState == .open)
            .blur(radius: abs(gestureProgress) > 0.3 ? min(gestureProgress, 8) : 0)
            
        }
    }
    
    @ViewBuilder
    func MusicLiveActivity() -> some View {
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
    
    private func doOpen() {
        viewModel.open()
        cancelHoverTimer()
    }
    
    private func checkHoverDuration() {
        guard let startTime = hoverStartTime else { return }
        
        let hoverDuraton = Date().timeIntervalSince(startTime)
        
        if hoverDuraton >= Defaults[.minimumHoverDuration] {
            doOpen()
        }
    }
    
    private func cancelHoverTimer() {
        hoverTimer?.invalidate()
        hoverTimer = nil
        hoverStartTime = nil
        
        withAnimation(viewModel.animation) {
            hoverAnimation = false
        }
    }
    
    private func startHoverTimer() {
        hoverStartTime = Date()
        hoverTimer?.invalidate()
        
        withAnimation(viewModel.animation) {
            hoverAnimation = true
        }
        
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            checkHoverDuration()
        }
    }
}

#Preview {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var musicManager: MusicManager = .init(viewModel: appDelegate.viewModel)!
    
    ContentView(
        onHover: appDelegate.adjustWindowPosition,
        batteryModel: .init(viewModel: appDelegate.viewModel)
    )
        .environmentObject(appDelegate.viewModel)
        .environmentObject(musicManager)
}
