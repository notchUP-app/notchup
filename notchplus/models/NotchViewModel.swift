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

class NotchViewModel: NSObject, ObservableObject {
    @ObservedObject var coordinator = NotchViewCoordinator.shared
    
    var cancellables: Set<AnyCancellable> = []
    var notifier: TheBoringWorkerNotifier = .init()
    var dragObserver: DragObserver?
    var screen: String?
    
    let animation: Animation?
    let animationLibrary: NotchAnimation = .init()
    let musicPlayerSizes: MusicPlayerElementSizes = .init()
    
    @Published var sizes: Sizes = .init()
    @Published var notchSize: CGSize = .init(width: Sizes().size.closed.width!, height: Sizes().size.closed.height!)
    @Published private(set) var notchState: NotchState = .closed
    @Published var notchMetastability: Bool = true // true if notch is closed
    
    @Published var spacing: CGFloat = 16
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    init(screen: String? = nil) {
        self.animation = animationLibrary.animation
        
        super.init()
        
        self.notifier = coordinator.notifier
        self.screen = screen
        
        self.firstLaunch = true
        self.dragObserver = DragObserver(viewModel: self)
        self.dragObserver?.startMonitoring()
        
        Publishers.CombineLatest($dropZoneTargeting, $dragDetectorTargetting)
            .map { value1, value2 in
                value1 || value2
            }
            .assign(to: \.anyDropZoneTargeting, on: self)
            .store(in: &cancellables)
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
