//
//  NotchShape.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 17/10/24.
//

import SwiftUI

struct NotchShape: Shape {
    var topCornerRadius: CGFloat {
        if bottomCornerRadius > 15 {
            bottomCornerRadius - 5
        } else {
            5
        }
    }
    
    var bottomCornerRadius: CGFloat
    
    init(cornerRadius: CGFloat? = nil) {
        if cornerRadius == nil {
            self.bottomCornerRadius = 10
        } else {
            self.bottomCornerRadius = cornerRadius!
        }
    }
    
    var animatableData: CGFloat {
        get { bottomCornerRadius }
        set { bottomCornerRadius = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // TOP LEFT CORNER
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // TOP LEFT INNER CURVE
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topCornerRadius, y: topCornerRadius),
            control: CGPoint(x: rect.minX + topCornerRadius, y: rect.minY)
        )
        
        // LEFT VERTICAL LINE
        path.addLine(to: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY - bottomCornerRadius))
        
        // BOTTOM LEFT CORNER
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topCornerRadius + bottomCornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY)
        )
        
        // BOTTOM HORIZONTAL LINE
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius - bottomCornerRadius, y: rect.maxY))
        
        // BOTTOM RIGHT CORNER
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - topCornerRadius, y: rect.maxY - bottomCornerRadius),
            control: CGPoint(x: rect.maxX - topCornerRadius, y: rect.maxY)
        )
        
        // RIGHT VERTICAL LINE
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius, y: rect.minY + bottomCornerRadius))
        
        // TOP RIGHT CORNER
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - topCornerRadius, y: rect.minY)
        )
        
        // TOP RIGHT CORNER
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        return path
    }
}

#Preview {
    NotchShape()
        .frame(width: 200, height: 80)
        .padding(10)
}
