//
//  DefaultModelView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import SwiftUI
import Combine
import TheBoringWorkerNotifier

struct sneak {
    var show: Bool = false
    var type: SneakContentType = .music
    var value: CGFloat = 0
    var icon: String = ""
}

struct ExpandedItem {
    var show: Bool = false
    var type: SneakContentType = .music
    var value: CGFloat = 0
    var browser: BrowserType = .chromium
}

class NotchViewModel: NSObject, ObservableObject {
    var cancellables: Set<AnyCancellable> = []
    
    let animation: Animation?
    let animationLibrary: NotchAnimations = .init()
    let musicPlayerSizes: MusicPlayerElementSizes = .init()
    
    var notifier: TheBoringWorkerNotifier = .init()
    @Published private(set) var notchState: NotchState = .closed
    @Published var notchMetastability: Bool = true // true if notch is closed
    
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    override init() {
        self.animation = animationLibrary.animation
        self.notifier = TheBoringWorkerNotifier()
        super.init()
    }
    
    @Published var sizes: Sizes = .init()
    @Published var notchSize: CGSize = .init(width: Sizes().size.closed.width!, height: Sizes().size.closed.height!)
    
    // ANIMATION METHODS
    func open() {
        withAnimation(.bouncy) {
            self.notchSize = .init(width: Sizes().size.opened.width!, height: Sizes().size.opened.height!)
            self.notchMetastability = true
            self.notchState = .open
        }
    }
    
    func close() {
        withAnimation(.smooth) {
            self.notchSize = .init(width: Sizes().size.closed.width!, height: Sizes().size.closed.height!)
            self.notchMetastability = false
            self.notchState = .closed
        }
    }
    
    func closeHello() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            self.firstLaunch = false
            withAnimation(self.animationLibrary.animation) {
                self.close()
            }
        }
    }
    
    func restartHello() {
        self.firstLaunch = true
        withAnimation(self.animationLibrary.animation) {
            self.open()
        }
    }
    
    @AppStorage("selected_screen") var selectedScreen = NSScreen.main?.localizedName ?? "Unknown Screen"
    
    // SNEAK METHODS
    private var sneakPeekDispatch: DispatchWorkItem?
    @Published var sneakPeek: sneak = .init() {
        didSet {
            if sneakPeek.show {
                sneakPeekDispatch?.cancel()
                
                sneakPeekDispatch = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                        
                    withAnimation {
                        self.toggleSneakPeek(status: false, type: SneakContentType.music)
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: sneakPeekDispatch!)
            }
        }
    }
    
    func toggleSneakPeek(status: Bool, type: SneakContentType, value: CGFloat = 0, icon: String = "") {
        if type != .music {
            close()
            if !hudReplacement {
                return
            }
        }
        
        DispatchQueue.main.async {
            withAnimation(.smooth) {
                self.sneakPeek.show = status
                self.sneakPeek.type = type
                self.sneakPeek.value = value
                self.sneakPeek.icon = icon
            }
        }
    }
    
    private var expandingViewDispatch: DispatchWorkItem?
    @Published var expandingView: ExpandedItem = .init() {
        didSet {
            if expandingView.show {
                expandingViewDispatch?.cancel()
                
                expandingViewDispatch = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    self.toggleExpandingView(status: false, type: SneakContentType.battery)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + (expandingView.type == .download ? 2 : 3), execute: expandingViewDispatch!)
            }
        }
    }
    func toggleExpandingView(status: Bool, type: SneakContentType, value: CGFloat = 0, browser: BrowserType = .chromium) {
        if expandingView.show {
            withAnimation(.smooth) {
                self.expandingView.show = false
            }
        }
        
        DispatchQueue.main.async {
            withAnimation(.smooth) {
                self.expandingView.show = status
                self.expandingView.type = type
                self.expandingView.value = value
                self.expandingView.browser = browser
            }
        }
    }
    
    @AppStorage("hudReplacement") var hudReplacement: Bool = true {
        didSet {
            toggleHudReplacement()
        }
    }
    func toggleHudReplacement() {
        // implement notifier
    }
    
    @Published var showMusicLiveActivityOnClosed: Bool = true
    func toggleMusicLiveActivityOnClosed(status: Bool) {
        withAnimation(.smooth) {
            self.showMusicLiveActivityOnClosed = status
        }
    }
}
