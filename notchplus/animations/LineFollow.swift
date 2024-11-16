//
//  LineFollow.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 15/11/24.
//

import SwiftUI

struct LineFollow<Content: Shape, Fill: ShapeStyle>: View, Animatable {
    var progress: Double
    var delay: Double = 1.0
    var fill: Fill
    var lineWidth = 4.0
    var blurRadius = 8.0
    
    @ViewBuilder var shape: Content
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    var body: some View {
        shape
            .trim(
                from: {
                    if progress > 1 - delay {
                        2 * progress - 1.0
                    } else if progress > delay {
                        progress - delay
                    } else {
                        .zero
                    }
                }(),
                to: progress
            )
            .glow(
                fill: fill,
                lineWidth: lineWidth,
                blurRadius: blurRadius
            )
    }
}
