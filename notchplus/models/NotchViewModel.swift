//
//  DefaultModelView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import SwiftUI
import Combine
import TheBoringWorkerNotifier

class NotchViewModel: NSObject, ObservableObject {
    var cancellables: Set<AnyCancellable> = []
    
    let animation: Animation?
    let animationLibrary: NotchAnimations = .init()
    @Published var sizes: Sizes = .init()
    
    var notifier: TheBoringWorkerNotifier = .init()
    @Published private(set) var notchState: NotchState = .closed
    @Published var notchMetastability: Bool = true // true if notch is closed
    
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    
    func destroy() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    deinit {
        destroy()
    }
    
    override init() {
        self.animation = animationLibrary.animation
        self.notifier = TheBoringWorkerNotifier()
        super.init()
    }
    
    @Published var notchSize: CGSize = .init(width: Sizes().size.closed.width!, height: Sizes().size.closed.height!)
    
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
    
}
