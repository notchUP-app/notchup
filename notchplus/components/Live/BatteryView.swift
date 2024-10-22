//
//  BatteryView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 21/10/24.
//

import SwiftUI

struct BatteryViewModel: View {
    @State var batteryLevel: Float
    @State var isCharging: Bool
    var batteryWidth: CGFloat = 30
    var animationStyle: NotchAnimations = NotchAnimations()
    
    var icon: String {
        return "battery.0"
    }
    
    var batteryColor: Color {
        if batteryLevel.isLessThanOrEqualTo(20) {
            return .red
        } else if isCharging {
            return .green
        } else {
            return .white
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Image(systemName: icon)
                .resizable()
                .fontWeight(.thin)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.gray)
                .frame(width: batteryWidth + 1)
                
            RoundedRectangle(cornerRadius: 2)
                .fill(batteryColor)
                .frame(
                    width: CGFloat(((CGFloat(CGFloat(batteryLevel)) / 100) * (batteryWidth - 6))),
                    height: (batteryWidth - 2.5) - 18
                )
                .padding(.leading, 2)
                .padding(.top, -0.5)
        }
    }
}


struct BatteryView: View {
    @State var batteryLevel: Float = 0
    @State var isPluggedIn: Bool = false
    @State var batteryWidth: CGFloat = 30
    
    var body: some View {
        HStack {
            Text("\(Int32(batteryLevel))%")
                .font(.callout)
                .foregroundStyle(.white)
            
            BatteryViewModel(
                batteryLevel: batteryLevel,
                isCharging: isPluggedIn,
                batteryWidth: batteryWidth
            )
        }
    }
}

#Preview {
    BatteryView(
        batteryLevel: 100,
        isPluggedIn: true,
        batteryWidth: 30
    )
        .frame(width: 200, height: 200)
}
