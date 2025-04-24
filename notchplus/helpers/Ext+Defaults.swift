//
//  Ext+Defaults.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 18/10/24.
//

import SwiftUI
import Defaults

extension Defaults.Keys {
    // MARK: GENERAL
    static let menuBarIcon = Key<Bool>("menuBarIcon", default: true)
    static let dropBoxByDefault = Key<Bool>("dropBoxByDefault", default: true)
    static let showOnAllDisplays = Key<Bool>("showOnAllDisplays", default: true)
    static let hideOnFullscreen = Key<Bool>("hideOnFullscreen", default: true)
    
    // MARK: APPEARENCE
    static let matchSystemAccent = Key<Bool>("matchSystemAccent", default: true)
    static let accentColor = Key<Color>("accentColor", default: Color.blue)
    static let cornerRadiusScaling = Key<Bool>("cornerRadiusScaling", default: true)
    
    static let enableShadow = Key<Bool>("enableShadow", default: true) // Remove
    
    // Media
    static let coloredSpectogram = Key<Bool>("coloredSpectogram", default: true)
    static let blurredArtwork = Key<Bool>("blurredArtwork", default: true)
    static let sliderColor = Key<SliderColorEnum>("sliderUseAlbumArtColor", default: SliderColorEnum.white)
    
    // Header
    static let showBattery = Key<Bool>("showBattery", default: true)
    static let settingsIconInNotch = Key<Bool>("settingsIconInNotch", default: true)
    static let settingsButtonAction = Key<NotchSettingsAction>("settingsIconAction", default: .app)
    
    // MARK: LIVE ACTIVITIES
    static let enableLiveActivities = Key<Bool>("enableLiveActivities", default: false)
    
    static let showChargingInfoOnPlug = Key<Bool>("showChargingInfoOnPlug", default: true)
    
    // Media
    static let enableFullScreenMediaDetection = Key<Bool>("enableFullScreenMediaDetection", default: true)
    static let enableSneekPeek = Key<Bool>("enableSneekPeek", default: false)
    static let musicPlayerWaitInterval = Key<Double>("musicPlayerWaitInterval", default: 3)
    static let preferredMediaController = Key<MediaControllerType>("preferredMediaController", default: defaultMediaController)
    static var defaultMediaController: MediaControllerType {
        if #available(macOS 15.4, *) {
            return .appleMusic
        } else {
            return .nowPlaying
        }
    }
    
    
    
    // MARK: HUD
    static let inlineHudShow = Key<Bool>("inlineHudShow", default: false)
    static let enableGradient = Key<Bool>("enableGradient", default: false)
    static let systemEventIndicatorUseAccent = Key<Bool>("systemEventIndicatorUseAccent", default: false)
    static let systemEventIndicatorShadow = Key<Bool>("systemEventIndicatorShadow", default: false)
    
    // MARK: HAPTICS
    static let minimumHoverDuration = Key<TimeInterval>("minimumHoverDuration", default: 0.3)
    static let openNotchOnHover = Key<Bool>("openNotchOnHover", default: true)
    static let enableHaptics = Key<Bool>("enableHaptics", default: true)
    
    // MARK: GESTURES
    static let enableGestures = Key<Bool>("enableGestures", default: true)
    static let closeGestureEnabled = Key<Bool>("closeGestureEnabled", default: true)
    static let gestureSensitivity = Key<CGFloat>("gestureSensitivity", default: 200.0)
}
