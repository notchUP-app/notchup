//
//  NotchViewCoordinator.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 25/03/25.
//

import Combine
import TheBoringWorkerNotifier
import SwiftUI
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
    var browser: BrowserType = .safari
}

class NotchViewCoordinator: ObservableObject {
    static let shared = NotchViewCoordinator()
    var notifier: TheBoringWorkerNotifier = .init()
    
    @Published var currentView: NotchViews = .home
    
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    @AppStorage("musicLiveActivity") var showMusicLiveOnClosed: Bool = true
    
    // MARK: - Selected Screen
    @Published var selectedScreen: String = NSScreen.main?.localizedName ?? "Unknown"
    @AppStorage("main_screen_name") var mainScreenName: String = NSScreen.main?.localizedName ?? "Unknown" {
        didSet {
            selectedScreen = mainScreenName
            NotificationCenter.default.post(name: Notification.Name.selectedScreenChanged, object: nil)
        }
    }
    
    private init() {
        selectedScreen = mainScreenName
        notifier = TheBoringWorkerNotifier()
    }
    
}
