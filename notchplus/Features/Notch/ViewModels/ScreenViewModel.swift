//
//  ScreenViewModel.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 10/11/24.
//

import SwiftUI
import AppKit

class ScreenViewModel: ObservableObject {
    @Published var screenSize: CGSize = .zero
    @Published var safeAreaInsets: NSEdgeInsets? = nil

    init() {
        self.updateScreenProperties()
        
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidChange), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    
    @objc func screenDidChange() {
        updateScreenProperties()
    }
    
    private func updateScreenProperties() {
        guard let screen = NSScreen.main else { return }
        
        self.screenSize = screen.frame.size
        self.safeAreaInsets = screen.safeAreaInsets
    }
    
}
