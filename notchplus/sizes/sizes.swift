//
//  sizes.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import SwiftUI

var closedNotchSize: CGSize = setNotchSize()

func setNotchSize(screen: String? = nil) -> CGSize {
    var notchHeight: CGFloat = 32
    var notchWidth: CGFloat = 185
    
    var selectedScreen = NSScreen.main
    
    if let customScreen = screen {
        selectedScreen = NSScreen.screens.first(where: {$0.localizedName == customScreen})
    }
    
    // check if screen is available
    if let screen = selectedScreen {
        // calc the exact size of the notch
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

struct Area {
    var width: CGFloat?
    var height: CGFloat?
    var inset: CGFloat?
}

struct StatesSizes {
    var opened: Area
    var closed: Area
}

struct Sizes {
    var cornerRadius: StatesSizes = StatesSizes(opened: Area(inset: 24), closed: Area(inset: 10))
    var size: StatesSizes = StatesSizes(
        opened: Area(width: 580, height: 150),
        closed: Area(width: closedNotchSize.width, height: closedNotchSize.height)
    )
}
