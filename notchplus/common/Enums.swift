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
    case battery = "🔋"
}

public enum CoverSize {
    static let small = CGSize(width: 50, height: 50)
    static let medium = CGSize(width: 100, height: 100)
    static let large = CGSize(width: 300, height: 300)
}

enum MediaControllerType: String, CaseIterable, Identifiable, Defaults.Serializable {
    case nowPlaying = "Now Playing"
    case appleMusic = "Apple Music"
//    case spotify = "Spotify"
    
    var id: String { self.rawValue }
}

enum MusicPlayerImageSizes {
    static let cornerRadiusInset: (opened: CGFloat, closed: CGFloat) = (opened: 13.0, closed: 4.0)
    static let size = (opened: CGSize(width: 90, height: 90), closed: CGSize(width: 20, height: 20))
}

enum BatteryEvent {
    case powerSourceChanged(isPluggedIn: Bool)
    case batteryLevelChanged(level: Float)
    case lowPowerModeChanged(isEnabled: Bool)
    case isChargingChanged(isCharging: Bool)
    case maxCapacityChanged(capacity: Float)
    case timeRemainingChanged(time: Int)
    case error(description: String)
}

enum BatteryError: Error {
    case powerSourceUnavailable
    case batteryInfoUnavailable(String)
    case batteryParameterMissing(String)
}
