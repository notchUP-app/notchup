//
//  Sizes.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import SwiftUI

struct Area {
    var width: CGFloat?
    var height: CGFloat?
    var inset: CGFloat?
    var insets: NSEdgeInsets?
}

struct NotchSizeState {
    var opened: Area
    var closed: Area
}

var closedNotchSize: CGSize = setNotchSize()

func setNotchSize(screen: String? = nil) -> CGSize {
    var notchHeight: CGFloat = 32
    var notchWidth: CGFloat = 185
    
    var selectedScreen = NSScreen.main
    
    if let customScreen = screen {
        selectedScreen = NSScreen.screens.first(where: {$0.localizedName == customScreen})
    }
    
    if let screen = selectedScreen {
        if let topLeftNotchPadding: CGFloat = screen.auxiliaryTopLeftArea?.width,
           let topRightNotchPadding: CGFloat = screen.auxiliaryTopRightArea?.width
        {
            notchWidth = screen.frame.width - topLeftNotchPadding - topRightNotchPadding + 10
        }
        
        // use menubar height if no notch
        notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
        
        // check if mac has no notch
        if screen.safeAreaInsets.top > 0 {
            notchHeight = screen.safeAreaInsets.top
        }
    }
    
    return .init(width: notchWidth, height: notchHeight)
}

struct Sizes {
    static let shared = Sizes()
    
    var cornerRadius: NotchSizeState = NotchSizeState(opened: Area(inset: 24), closed: Area(inset: 10))
    var size: NotchSizeState = NotchSizeState(
        opened: Area(width: 580, height: 175),
        closed: Area(width: closedNotchSize.width, height: closedNotchSize.height)
    )
}

struct MusicPlayerElementSizes {
    var baseSize: Sizes = Sizes()
    
    var image: Sizes = Sizes(
        cornerRadius: NotchSizeState(opened: Area(inset: 13), closed: Area(inset: 4)),
        size: NotchSizeState(opened: Area(width: 90, height: 90), closed: Area(width: 20, height: 20))
    )
    
    var player: Sizes = Sizes(
        size: NotchSizeState(
            opened: Area(width: 440), closed: Area(width: closedNotchSize.width)
        )
    )
}

var screenSize: Area = setScreenSize()

func setScreenSize(screen: String? = nil) -> Area {
    var screenSize: CGSize = .zero
    var safeAreaInsets: NSEdgeInsets? = nil
    
    guard let screen = NSScreen.main else { return .init() }
    
    screenSize = screen.frame.size
    safeAreaInsets = screen.safeAreaInsets
    
    return .init(width: screenSize.width, height: screenSize.height, insets: safeAreaInsets)
}
