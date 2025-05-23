//
//  ContentView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import Defaults
import SwiftUI

struct ContentView: View {
    let onHover: (Bool) -> Void

    @ObservedObject var coordinator: NotchViewCoordinator
    @ObservedObject var viewModel: NotchViewModel
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @ObservedObject var musicManager = MusicManager.shared

    @State private var hoverStartTime: Date?
    @State private var hoverTimer: Timer?
    @State private var hoverAnimation: Bool = false
    @State private var gestureProgress: CGFloat = .zero
    @State private var haptics: Bool = false

    @State private var maxWidth: CGFloat = 269
    @State private var maxHeight: CGFloat = Sizes().size.opened.height! + 20

    @AppStorage("firstLaunch") private var firstLaunch: Bool = false

    init (
        onHover: @escaping (Bool) -> Void,
        coordinator: NotchViewCoordinator = .shared,
        viewModel: NotchViewModel
    ) {
        self.onHover = onHover
        self.coordinator = coordinator
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            NotchLayout(
                hoverAnimation: $hoverAnimation,
                gestureProgress: $gestureProgress
            )
            .padding(
                .horizontal,
                viewModel.notchState == .open
                ? Defaults[.cornerRadiusScaling]
                ? (viewModel.sizes.cornerRadius.opened.inset! - 5)
                : (viewModel.sizes.cornerRadius.closed.inset! - 5)
                : 12
            )
            .padding(
                [.horizontal, .bottom],
                viewModel.notchState == .open ? 12 : 0
            )
            .frame(
                maxWidth: calculateMaxWidth(),
                maxHeight: calculateMaxHeight(),
                alignment: .top
            )
            .background(.black)
            .mask {
                NotchShape(
                    cornerRadius: ((viewModel.notchState == .open)
                                   && Defaults[.cornerRadiusScaling])
                    ? viewModel.sizes.cornerRadius.opened.inset
                    : viewModel.sizes.cornerRadius.closed.inset)
            }
            .frame(
                width: calculateWidth(),
                height: calculateHeight(),
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
            .conditionalModifier(Defaults[.closeGestureEnabled] && Defaults[.enableGestures]) {
                view in
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
                        if coordinator.firstLaunch {
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
        .frame(
            maxWidth: Sizes().size.opened.width! + 40,
            maxHeight: Sizes().size.opened.height! + 20,
            alignment: .top
        )
        .shadow(
            color: (viewModel.notchState == .open && Defaults[.enableShadow]
                    ? .black.opacity(0.6) : .clear),
            radius: Defaults[.cornerRadiusScaling] ? 10 : 5
        )
        .background(dragDetector)
        .environmentObject(viewModel)
        .trackLifecycle(identifier: "ContentView")
    }

    @ViewBuilder
    var dragDetector: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onDrop(of: [.data], isTargeted: $viewModel.dragDetectorTargetting) { _ in true }
            .onChange(of: viewModel.anyDropZoneTargeting) { _, isTargeted in
                if isTargeted, viewModel.notchState == .closed {
                    coordinator.currentView = .home
                    doOpen()
                } else if !isTargeted {
                    Logger.log("Drop event: \(viewModel.dropEvent)", type: .debug)
                    if viewModel.dropEvent {
                        viewModel.dropEvent = false
                        return
                    }

                    viewModel.dropEvent = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        Logger.log("Closing", type: .debug)
                        viewModel.close()
                    }
                }
            }

    }

    private func doOpen() {
        viewModel.open()
        cancelHoverTimer()
    }

    // MARK: - Hover Handling

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

    // MARK: - Size Calculations

    private func calculateMaxWidth() -> CGFloat? {
        if (musicManager.isPlaying || !musicManager.isPlayerIdle) && viewModel.notchState == .closed && viewModel.showMusicLiveActivityOnClosed {
            return nil
        }

        if viewModel.expandingView.show && viewModel.expandingView.type == .battery {
            return nil
        }

        if Defaults[.inlineHudShow] {
            return nil
        }

        return viewModel.notchSize.width + ((hoverAnimation || viewModel.notchState == .closed) ? 20 : 0) + gestureProgress
    }
    private func calculateMaxHeight() -> CGFloat? {
        //        if (viewModel.sneakPeek.show && viewModel.sneakPeek.type != .music) || (viewModel.sneakPeek.show && viewModel.sneakPeek.type == .music && viewModel.notchState == .closed) {
        //            return nil
        //        }

        return viewModel.notchSize.height + (hoverAnimation ? 8 : 0) + gestureProgress / 3
    }
    private func calculateWidth() -> CGFloat? {
        if viewModel.notchState == .closed {
            if (
                (musicManager.isPlaying || !musicManager.isPlayerIdle) && viewModel.showMusicLiveActivityOnClosed
                || (viewModel.expandingView.show && viewModel.expandingView.type == .battery)
            ) {
                return nil
            }

            return Sizes().size.closed.width! + (hoverAnimation ? 20 : 0) + gestureProgress
        }

        return nil
    }
    private func calculateHeight() -> CGFloat? {
        if (viewModel.notchState == .closed) {
            return Sizes().size.closed.height! + (hoverAnimation ? 8 : 0) + gestureProgress / 3
        }

        return nil
    }
}

#Preview {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    ContentView(
        onHover: appDelegate.adjustWindowPosition,
        coordinator: NotchViewCoordinator.shared,
        viewModel: appDelegate.viewModel
    )
    .environmentObject(appDelegate.viewModel)
}
