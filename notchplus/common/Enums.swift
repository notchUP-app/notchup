//
//  Enums.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import Foundation
import Defaults
import SwiftUI

public enum Style {
    case notch
    case floating
}

public enum NotchState {
    case open
    case closed
}

public enum BrowserType {
    case safari
    case chromium
}

public enum NotchViews {
    case home
}

public enum SliderColorEnum: String, CaseIterable, Defaults.Serializable {
    case white = "White"
    case albumArt = "Match album art"
    case accent = "Accent color"
}

enum NotchSettingsAction: String, CaseIterable, Defaults.Serializable {
    case app = "App Settings"
    case system = "System Settings"
}

enum LogType: String {
    case success = "✅"
    case error = "❌"
    case warning = "⚠️"
    case info = "ℹ️"
    case debug = "🔍"
    case lifecycle = "🔄"
    case ui = "🎨"
    case memory = "💾"
    case network = "🌐"
    case media = "🎵"
}

public enum CoverSize {
    static let small = CGSize(width: 50, height: 50)
    static let medium = CGSize(width: 100, height: 100)
    static let large = CGSize(width: 300, height: 300)
}
