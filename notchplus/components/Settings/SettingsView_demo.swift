//
//  SettingsView_demo.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 14/11/24.
//

import SwiftUI
import Cocoa

struct SettingsViewDemo: View {
    @EnvironmentObject var viewModel: NotchViewModel
    @State private var selection: Int = 0
    
    var body: some View {
       TabView(selection: $selection) {
           Tab("General", systemImage: "gearshape.fill", value: 0) {
               GeneralSettings()
           }
           Tab("Appearance", systemImage: "star.fill", value: 1) {
               EmptyView()
           }
           Tab("About", systemImage: "info.circle.fill", value: 2) {
               AboutUsView()
           }
       }
       .tabViewStyle(.sidebarAdaptable)
        .frame(width: 700, height: 400)
        .padding()
    }
    
}

class SettingsWindowViewController: NSViewController {
    override func loadView() {
        view = NSHostingView(rootView: SettingsViewDemo())
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
