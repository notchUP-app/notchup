//
//  Constants.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 18/10/24.
//

import SwiftUI
import Defaults

extension Defaults.Keys {
    // GENERAL
    static let menuBarIcon = Key<Bool>("menuBarIcon", default: true)
    static let openShelfByDefault = Key<Bool>("openShelfByDefault", default: false)
    
    // APPEARENCE
    static let cornerRadiusScaling = Key<Bool>("cornerRadiusScaling", default: true)
    static let enableShadow = Key<Bool>("enableShadow", default: true)
    static let settingsIconInNotch = Key<Bool>("settingsIconInNotch", default: false)
    static let accentColor = Key<Color>("accentColor", default: Color.blue)
    
    // MEDIA PLAYBACK
    static let coloredSpectogram = Key<Bool>("coloredSpectogram", default: true)
    static let enableFullScreenMediaDetection = Key<Bool>("enableFullScreenMediaDetection", default: true)
    static let enableSneekPeek = Key<Bool>("enableSneekPeek", default: false)
    static let waitInterval = Key<Double>("waitInterval", default: 3)
    
    // HUD
    static let inlineHUD = Key<Bool>("inlineHUD", default: false)
    static let enableGradient = Key<Bool>("enableGradient", default: false)
    static let systemEventIndicatorUseAccent = Key<Bool>("systemEventIndicatorUseAccent", default: false)
    static let systemEventIndicatorShadow = Key<Bool>("systemEventIndicatorShadow", default: false)
    
    // HAPTICS
    static let minimumHoverDuration = Key<TimeInterval>("minimumHoverDuration", default: 0.3)
    static let openNotchOnHover = Key<Bool>("openNotchOnHover", default: true)
    static let enableHaptics = Key<Bool>("enableHaptics", default: true)
    
    // GESTURES
    static let enableGestures = Key<Bool>("enableGestures", default: true)
    static let closeGestureEnabled = Key<Bool>("closeGestureEnabled", default: true)
    static let gestureSensitivity = Key<CGFloat>("gestureSensitivity", default: 200.0)
    
    // BATTERY
    static let chargingInfoAllowed = Key<Bool>("chargingInfoAllowed", default: true)
    static let showBattery = Key<Bool>("showBattery", default: true)
}
