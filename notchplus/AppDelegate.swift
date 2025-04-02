//
//  AppDelegate.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 18/10/24.
//

import SwiftUI
import Defaults

class AppDelegate: NSObject, NSApplicationDelegate {
    @ObservedObject var coordinator = NotchViewCoordinator.shared
    
    var viewModel: NotchViewModel = NotchViewModel.shared
    var viewModels: [NSScreen: NotchViewModel] = [:]
    
    var window: NSWindow!
    var windows: [NSScreen: NSWindow] = [:]
    private var previousScreen: [NSScreen]?
    
    var animationWindow: NSWindow?
    let sizing: Sizes = .init()
    private var previousScreens: [NSScreen]?

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(onScreenLocked(_:)),
            name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"),
            object: nil
        )
        
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(onScreenUnlocked(_:)),
            name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"),
            object: nil
        )
        
        if coordinator.firstLaunch {
            DispatchQueue.main.async {
                self.showAnimationOverlay()
            }
        } else {
            createAndShowMainWindow()
        }
        
        
    }

    @objc func adjustWindowPosition(changeAlpha: Bool = false) {
        if Defaults[.showOnAllDisplays] {
            for screen in NSScreen.screens {
                if windows[screen] == nil {
                    let viewModel: NotchViewModel = .init(screen: screen.localizedName)
                    let window = NotchUpWindow(
                        contentRect: NSRect(
                            x: 0, y: 0, width: sizing.size.opened.width! + 20, height: sizing.size.opened.height! + 30
                        ),
                        styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
                        backing: .buffered,
                        defer: false
                    )
                    
                    window.contentView = NSHostingView(
                        rootView: ContentView(
                            onHover: adjustWindowPosition,
                            coordinator: NotchViewCoordinator.shared,
                            viewModel: viewModel,
                            batteryModel: .init(viewModel: viewModel)
                        )
                        .environmentObject(viewModel)
                        .environmentObject(MusicManager(viewModel: viewModel)!)
                    )
                    
                    windows[screen] = window
                    viewModels[screen] = viewModel
                    window.orderFrontRegardless()
                    
                }
                
                if let window = windows[screen] {
                    window.alphaValue = changeAlpha ? 0 : 1
                    
                    DispatchQueue.main.async {
                        let screenFrame = screen.frame
                        window.setFrameOrigin(
                            NSPoint(
                                x: screenFrame.origin.x + (screenFrame.width / 2) - window.frame.width / 2,
                                y: screenFrame.origin.y + screenFrame.height - window.frame.height
                            )
                        )
                        
                        window.alphaValue = 1
                    }
                }
                
                if let viewModel = viewModels[screen] {
                    if viewModel.notchState == .closed {
                        viewModel.close()
                    }
                }
            }
        }
        else {
            if !NSScreen.screens.contains(where: { $0.localizedName == coordinator.selectedScreen }) {
                coordinator.selectedScreen = NSScreen.main?.localizedName ?? "Unknown"
            }

            let selectedScreen = NSScreen.screens.first(where: {
                $0.localizedName == coordinator.selectedScreen
            })
            closedNotchSize = setNotchSize(screen: selectedScreen?.localizedName)

            if let screenFrame = selectedScreen {
                window.alphaValue = changeAlpha ? 0 : 1
                window.makeKeyAndOrderFront(nil)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    let origin = screenFrame.frame.origin.applying(
                        CGAffineTransform(
                            translationX: (screenFrame.frame.width / 2) - window.frame.width / 2,
                            y: screenFrame.frame.height - window.frame.height
                        )
                    )

                    window.setFrameOrigin(origin)
                    window.alphaValue = 1
                }
            }
            
            if viewModel.notchState == .closed {
                viewModel.close()
            }
        }
    }

    private func showAnimationOverlay() {
        animationWindow = NSWindow(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        animationWindow?.level = .mainMenu + 1
        animationWindow?.backgroundColor = .clear
        animationWindow?.isOpaque = false
        animationWindow?.ignoresMouseEvents = true

        animationWindow?.contentView = NSHostingView(
            rootView: LaunchAnimationView {
                DispatchQueue.main.async {
                    self.createAndShowMainWindow()
                    self.animationWindow?.orderOut(nil)
                    self.animationWindow = nil
                }
            }
        )

        animationWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func cleanupWindows() {
        if Defaults[.showOnAllDisplays] {
            for window in windows.values {
                window.close()
                SpaceManager.shared.space.windows.remove(window)
            }
            
            windows.removeAll()
            viewModels.removeAll()
        }
        else if let window = window {
            window.close()
            SpaceManager.shared.space.windows.remove(window)
        }
    }
    
    @objc func onScreenLocked(_ : Notification) {
        Logger.log("Screen locked", type: .debug)
        cleanupWindows()
    }
    
    @objc func onScreenUnlocked(_ : Notification) {
        Logger.log("Screen unlocked", type: .debug)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.cleanupWindows()
//            self?.showAnimationOverlay()
            self?.adjustWindowPosition()
        }
    }
    
    @objc func screenConfigurationDidChange() {
        let currentScreens = NSScreen.screens
        let screensChanged = currentScreens.count != previousScreens?.count ||
        Set(currentScreens.map { $0.localizedName }) != Set(previousScreens?.map { $0.localizedName } ?? [])
        
        if screensChanged {
            Logger.log("Screens changed", type: .debug)
            
            previousScreens = currentScreens
            cleanupWindows()
            adjustWindowPosition()
        }
    }
    
    private func createAndShowMainWindow() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name.selectedScreenChanged,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.adjustWindowPosition(changeAlpha: true)
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.notchHeightChanged,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.adjustWindowPosition()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.showOnAllDisplaysChanged,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            if (!Defaults[.showOnAllDisplays]) {
                self?.window = NotchUpWindow(
                    contentRect: NSRect(x: 0, y: 0, width: Sizes.shared.size.opened.width!, height: Sizes.shared.size.opened.height!),
                    styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
                    backing: .buffered,
                    defer: false
                )
                
                if let windowValues = self?.windows.values {
                    for window in windowValues {
                        window.close()
                    }
                }
                
                self?.window.contentView = NSHostingView(
                    rootView: ContentView(
                        onHover: self!.adjustWindowPosition,
                        coordinator: NotchViewCoordinator.shared,
                        viewModel: self!.viewModel,
                        batteryModel: .init(viewModel: self!.viewModel)
                    )
                    .environmentObject(self!.viewModel)
                    .environmentObject(MusicManager(viewModel: self!.viewModel)!)
                )
                
                self?.adjustWindowPosition(changeAlpha: true)
                
                self?.window.orderFrontRegardless()
                
                SpaceManager.shared.space.windows.insert(self!.window)
            }
            else {
                self?.window.close()
                self?.windows = [:]
                self?.adjustWindowPosition()
            }
        }
        
        if !Defaults[.showOnAllDisplays] {
            window = NotchUpWindow(
                contentRect: NSRect(x: 0, y: 0, width: Sizes.shared.size.opened.width!, height: Sizes.shared.size.opened.height!),
                styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
                backing: .buffered,
                defer: false
            )
            
            window.contentView = NSHostingView(
                rootView: ContentView(
                    onHover: adjustWindowPosition,
                    coordinator: NotchViewCoordinator.shared,
                    viewModel: viewModel,
                    batteryModel: .init(viewModel: viewModel)
                )
                .environmentObject(viewModel)
                .environmentObject(MusicManager(viewModel: viewModel)!)
            )
            
            adjustWindowPosition(changeAlpha: true)
            
            window.orderFrontRegardless()
            
            SpaceManager.shared.space.windows.insert(window)
        } else {
            adjustWindowPosition()
        }
    }
}
