//
//  SettingsView_demo.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 14/11/24.
//

import SwiftUI
import Cocoa

struct SettingsView: View {
    @EnvironmentObject var viewModel: NotchViewModel
    @State private var selection: Int = 0
    @State private var showDeveloperTab: Bool = false
    
    var body: some View {
        TabView(selection: $selection) {
            Tab("General", systemImage: "gearshape", value: 0) {
                GeneralView()
            }
            Tab("Gestures", systemImage: "hand.draw.fill", value: 1) {
                GesturesView()
            }
            Tab("Appearance", systemImage: "star.fill", value: 2) {
                AppearanceView()
            }
            Tab("Live", systemImage: "music.note.house.fill", value: 3) {
                LiveView()
            }
            Tab("About", systemImage: "info.circle", value: 4) {
                AboutView()
            }
            
            if showDeveloperTab {
                Tab("Developer", systemImage: "hammer.fill", value: 5) {
                    DeveloperView()
                }
            }
        }
        .tabViewStyle(.tabBarOnly)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.control) && event.keyCode == 34 {
                    showDeveloperTab.toggle()
                    return nil
                }
                return event
            }
        }
    }
    
}

class SettingsWindowViewController: NSViewController {
    override func loadView() {
        view = NSHostingView(rootView: SettingsView())
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = "Settings"
        view.window?.level = .floating
        view.window?.makeKeyAndOrderFront(nil)
    }
}

struct SettingsWindow: NSViewControllerRepresentable {
    static var window: NSWindow?
    
    func makeNSViewController(context: Context) -> some NSViewController {
        let viewController = SettingsWindowViewController()
        return viewController
    }
    
    func updateNSViewController(_ nsViewController: some NSViewController, context: Context) {}
}

#Preview("Settings") {
    SettingsWindow()
        .environmentObject(NotchViewModel())
        .frame(width: 500, height: 580)
}

#Preview("NSHosting") {
    NSHostingController(
        rootView: SettingsView()
            .environmentObject(NotchViewModel())
            .frame(width: 500, height: 580)
    )
    .view
}
