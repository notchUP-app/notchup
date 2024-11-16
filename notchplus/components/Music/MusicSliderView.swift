//
//  MusicSliderView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 15/11/24.
//

import SwiftUI
import Defaults

struct MusicSliderView: View {
    @Binding var sliderValue: Double
    @Binding var duration: Double
    @Binding var dragging: Bool
    @Binding var lastDragged: Date
    
    var color: NSColor
    var onValueChange: ((Double) -> Void)
    
    var body: some View {
        VStack {
            CustomSlider(
                value: $sliderValue,
                range: 0...duration,
                color: Defaults[.sliderColor] == SliderColorEnum.albumArt
                ? Color(nsColor: color)
                : Defaults[.sliderColor] == SliderColorEnum.accent
                ? Defaults[.accentColor] : .white,
                dragging: $dragging,
                lastDragged: $lastDragged,
                onValueChange: onValueChange
            )
            .frame(height: 10, alignment: .center)
            HStack {
                Text(timeString(from: sliderValue))
                Spacer()
                Text(timeString(from: duration))
            }
            .fontWeight(.medium)
            .foregroundColor(.gray)
            .font(.caption)
        }
    }
    
    func timeString(from seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
