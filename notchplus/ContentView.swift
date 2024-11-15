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
    
    @State private var maxWidth: CGFloat = 269
    @State private var maxHeight: CGFloat = Sizes().size.opened.height! + 20
    
    @Namespace var albumArtNamespace
    @AppStorage("firstLaunch") private var firstLaunch: Bool = false
    
    var body: some View {
        ZStack {
            NotchLayout()
                .padding(.horizontal, viewModel.notchState == .open ? Defaults[.cornerRadiusScaling] ? (viewModel.sizes.cornerRadius.opened.inset! - 5) : (viewModel.sizes.cornerRadius.closed.inset! - 5) : 12)
                .padding([.horizontal, .bottom], viewModel.notchState == .open ? 12 : 0)
                .frame(
                    maxWidth: (((musicManager.isPlaying || !musicManager.isPlayerIdle) && viewModel.notchState == .closed && viewModel.showMusicLiveActivityOnClosed) || (viewModel.expandingView.show && (viewModel.expandingView.type == .battery)) || Defaults[.inlineHudShow]) ? nil : viewModel.notchSize.width + ((hoverAnimation || (viewModel.notchState == .closed)) ? 20 : 0) + gestureProgress,
                    maxHeight: ((viewModel.sneakPeek.show && viewModel.sneakPeek.type != .music) || (viewModel.sneakPeek.show && viewModel.sneakPeek.type == .music && viewModel.notchState == .closed)) ? nil : viewModel.notchSize.height + (hoverAnimation ? 8 : 0) + gestureProgress / 3,
                    alignment: .top
                )
                .background(.black)
                .mask {
                    NotchShape(cornerRadius: ((viewModel.notchState == .open) && Defaults[.cornerRadiusScaling]) ? viewModel.sizes.cornerRadius.opened.inset : viewModel.sizes.cornerRadius.closed.inset)
                }
                .frame(
                    width: viewModel.notchState == .closed ? (((musicManager.isPlaying || !musicManager.isPlayerIdle) && viewModel.showMusicLiveActivityOnClosed) || (viewModel.expandingView.show && (viewModel.expandingView.type == .battery)) || (Defaults[.inlineHudShow] && viewModel.sneakPeek.type != .music)) ? nil : Sizes().size.closed.width! + (hoverAnimation ? 20 : 0) + gestureProgress : nil,
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
                }
        }
        // FIXME: FRAME COVERING THE WHOLE NOTCH OPENED WHEN OPPENING LAUNCH ANIMATION
//        .frame(
//            maxWidth: viewModel.notchSize.width + 40,
//            maxHeight: viewModel.notchSize.height + 20,
//            alignment: .top
//        )
        .frame(
            maxWidth: Sizes().size.opened.width! + 40,
            maxHeight: Sizes().size.opened.height! + 20,
            alignment: .top
        )
        .shadow(color: (viewModel.notchState == .open && Defaults[.enableShadow] ? .black.opacity(0.6) : .clear), radius: Defaults[.cornerRadiusScaling] ? 10 : 5)
        .background(dragDetector)
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
                            self.maxWidth = Sizes().size.opened.width! + 40
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
                            gestureProgress: $gestureProgress
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

    
    @ViewBuilder
    var dragDetector: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onDrop(of: [.data], isTargeted: $viewModel.dragDetectorTargetting) { _ in true }
            .onChange(of: viewModel.anyDropZoneTargeting) { _, isTargeted in
                if isTargeted, viewModel.notchState == .closed {
                    viewModel.currentView = .home
                    doOpen()
                } else if !isTargeted {
                    print("Drop event: ", viewModel.dropEvent)
                    if viewModel.dropEvent {
                        viewModel.dropEvent = false
                        return
                    }
                    
                    viewModel.dropEvent = false
                    viewModel.close()
                }
            }
        
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
    
    ContentView(
        onHover: appDelegate.adjustWindowPosition,
        batteryModel: .init(viewModel: appDelegate.viewModel)
    )
        .environmentObject(appDelegate.viewModel)
        .environmentObject(MusicManager(viewModel: appDelegate.viewModel)!)
}
