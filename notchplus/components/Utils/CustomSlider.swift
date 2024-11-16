//
//  CustomSlider.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 15/11/24.
//

import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var color: Color = .white
    @Binding var dragging: Bool
    @Binding var lastDragged: Date
    var onValueChange: ((Double) -> Void)?
    var thumbSize: CGFloat = 12
    @State private var hovered: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let rangeSpan = range.upperBound - range.lowerBound
            
            let filledTrackWidth = rangeSpan == .zero ? 0 : ((value - range.lowerBound) / rangeSpan) * width
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                Capsule()
                    .fill(color)
                    .frame(width: filledTrackWidth, height: height)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        withAnimation {
                            dragging = true
                        }
                        let newValue = range.lowerBound + Double(gesture.location.x / width) * rangeSpan
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        onValueChange?(value)
                        dragging = false
                        lastDragged = Date()
                    }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    withAnimation {
                        hovered = true
                    }
                case .ended:
                    withAnimation {
                        hovered = false
                    }
                }
            }
        }
        .frame(height: dragging || hovered ? 8 : 5)
    }
}
