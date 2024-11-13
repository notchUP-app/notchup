//
//  DefaultModelView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import SwiftUI
import Combine
import TheBoringWorkerNotifier
import Defaults

struct Sneak {
    var show: Bool = false
    var type: SneakContentType = .music
    var value: CGFloat = 0
    var icon: String = ""
}

struct SharedSneakPeek: Codable {
    var show: Bool
    var type: String
    var value: String
    var icon: String
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
    
    @Published var sizes: Sizes = .init()
    @Published var notchSize: CGSize = .init(width: Sizes().size.closed.width!, height: Sizes().size.closed.height!)
    @Published private(set) var notchState: NotchState = .closed
    @Published var notchMetastability: Bool = true // true if notch is closed
    @Published var spacing: CGFloat = 16
    
    @Published var currentView: NotchViews = .home
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    
    var notifier: TheBoringWorkerNotifier = .init()
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    override init() {
        self.animation = animationLibrary.animation
        self.notifier = TheBoringWorkerNotifier()
        
        super.init()
        // FIRST LAUNCH ANIMATION TAG
        self.firstLaunch = false
        
        Publishers.CombineLatest($dropZoneTargeting, $dragDetectorTargetting)
            .map { value1, value2 in
                value1 || value2
            }
            .assign(to: \.anyDropZoneTargeting, on: self)
            .store(in: &cancellables)
    }
    
    func setupWorkersNotificationsObservers() {
        notifier.setupObserver(notification: notifier.sneakPeakNotification, handler: sneakPeekEvent)
        notifier.setupObserver(notification: notifier.micStatusNotification, handler: initialMicStatus)
    }
    
    // MARK: - SneakPeek
    private var sneakPeekDispatch: DispatchWorkItem?
    
    @Published var sneakPeek: Sneak = .init() {
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
    
    @objc func sneakPeekEvent(_ notification: Notification) {
        let decoder = JSONDecoder()
        if let decodedData = try? decoder.decode(SharedSneakPeek.self, from: notification.userInfo?.first?.value as! Data) {
            let contentType =
            decodedData.type == "brightness" ? SneakContentType.brightness
            : decodedData.type == "volume" ? SneakContentType.volume
            : decodedData.type == "backlight" ? SneakContentType.backlight
            : decodedData.type == "mic" ? SneakContentType.mic
            : SneakContentType.brightness
            
            let value = CGFloat((NumberFormatter().number(from: decodedData.value) ?? 0.0).floatValue)
            let icon = decodedData.icon
            
            print("Decoded Data: \(decodedData)")
            toggleSneakPeek(status: decodedData.show, type: contentType, value: value, icon: icon)
        } else {
            print("Failed to decode JSON data")
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
        
        if (type == .mic) {
            currentMicStatus = value == 1
        }
    }
    
    // MARK: - Expanding View
    
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
    
    // MARK: - View Variables
    
    @AppStorage("selected_screen") var selectedScreen = NSScreen.main?.localizedName ?? "Unknown Screen" {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.selectedScreenChanged, object: nil)
        }
    }
    
    @AppStorage("currentMicStatus") var currentMicStatus: Bool = false
    @objc func initialMicStatus(_ notification: Notification) {
        self.currentMicStatus = notification.userInfo?.first?.value as! Bool
    }
    
    @AppStorage("openLastTabByDefault") var openLastTabByDefault: Bool = true {
        didSet {
            if openLastTabByDefault {
                alwaysShowTabs = true
            }
        }
    }
    
    @AppStorage("hudReplacement") var hudReplacement: Bool = true {
        didSet {
            toggleHudReplacement()
        }
    }
    func toggleHudReplacement() {
        notifier.postNotification(name: notifier.toggleHudReplacementNotification.name, userInfo: nil)
    }
    
    @AppStorage("alwaysShowTabs") var alwaysShowTabs: Bool = true {
        didSet {
            if !alwaysShowTabs {
                openLastTabByDefault = false
                if !Defaults[.openShelfByDefault] {
                    currentView = .home
                }
            }
        }
    }
    
    @Published var showMusicLiveActivityOnClosed: Bool = true
    func toggleMusicLiveActivityOnClosed(status: Bool) {
        withAnimation(.smooth) {
            self.showMusicLiveActivityOnClosed = status
        }
    }
    
    // MARK: - Notch State
    
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(self.animationLibrary.animation) {
                self.close()
                self.firstLaunch = false
            }
        }
    }
    
    func restartHello() {
        self.firstLaunch = true
        withAnimation(self.animationLibrary.animation) {
            self.open()
        }
    }
    
    // MARK: - Drag-n-Drop Variables
    
    @Published var dragDetectorTargetting: Bool = false
    @Published var dropZoneTargeting: Bool = false
    @Published var dropEvent: Bool = false
    @Published var anyDropZoneTargeting: Bool = false
    
}
