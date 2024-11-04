//
//  generic.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import Foundation
import Defaults

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
