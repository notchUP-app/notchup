//
//  Ext+Shape.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 10/11/24.
//

import SwiftUI

extension ShapeStyle where Self == AngularGradient {
    static var hello: some ShapeStyle {
        LinearGradient(
            stops: [
                .init(color: .red, location: 0.0),
                .init(color: .purple, location: 0.2),
                .init(color: .yellow, location: 0.4),
                .init(color: .blue, location: 0.6),
                .init(color: .green, location: 0.8),
                .init(color: .white, location: 1.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var openAnimation: some ShapeStyle {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0.0),
                .init(color: .blue, location: 0.2),
                .init(color: .red, location: 0.4),
                .init(color: .red, location: 0.6),
                .init(color: .blue, location: 0.8),
                .init(color: .white, location: 1.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
