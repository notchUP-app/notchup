//
//  Constants.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 18/10/24.
//

import Foundation
import Defaults

extension Defaults.Keys {
    // APPEARENCE
    static let cornerRadiusScaling = Key<Bool>("cornerRadiusScaling", default: true)
    static let enableShadow = Key<Bool>("enableShadow", default: true)
    
    // MEDIA PLAYBACK
    static let coloredSpectogram = Key<Bool>("coloredSpectogram", default: true)
    static let enableFullScreenMediaDetection = Key<Bool>("enableFullScreenMediaDetection", default: true)
    static let enableSneekPeek = Key<Bool>("enableSneekPeek", default: false)
    static let waitInterval = Key<Double>("waitInterval", default: 3)
}
