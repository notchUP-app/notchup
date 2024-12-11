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
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        if seconds.isNaN {
            return "0:00"
        } else if seconds >= 3600 {
            formatter.allowedUnits = [.hour, .minute, .second]
            return formatter.string(from: seconds) ?? "0:00"
        
        } else {
            formatter.allowedUnits = [.minute, .second]
            return formatter.string(from: seconds) ?? "0:00"
        }
    }
}
