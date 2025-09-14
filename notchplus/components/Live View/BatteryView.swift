//
//  BatteryView.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 21/10/24.
//

import SwiftUI

struct BatteryViewModel: View {
    
    var batteryLevel: Float
    var isPluggedIn: Bool
    var isCharging: Bool
    var isInLowPowerMode: Bool
    var batteryWidth: CGFloat = 26
    var isForNotification: Bool
    
    var animationStyle: NotchAnimation = NotchAnimation()
    
    var icon: String = "battery.0"
    
    var iconStatus: String {
        if isCharging {
            return "bolt.fill"
        }
        else if isPluggedIn {
            return "powerplug.portrait.fill"
        }
        else {
            return ""
        }
    }
    
    var batteryColor: Color {
        if isInLowPowerMode {
            return .yellow
        }
        else if batteryLevel.isLessThanOrEqualTo(20) && !isPluggedIn && !isCharging {
            return .red
        } else if isCharging || isPluggedIn || batteryLevel.isEqual(to: 100) {
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
            
            if iconStatus != "" {
                ZStack {
                    Image(systemName: iconStatus)
                        .resizable()
                        .fontWeight(.light)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .frame(width: 15, height: 15)
                }
                .frame(width: batteryWidth, height: batteryWidth)
            }
        }
    }
}


struct BatteryView: View {
    @State var batteryWidth: CGFloat = 30
    
    var batteryLevel: Float = 0
    var isCharging: Bool = false
    var isPluggedIn: Bool = false
    var isInLowPowerMode: Bool = false
    @State var isForNotification: Bool = true
    
    var body: some View {
        HStack {
            Text("\(Int32(batteryLevel))%")
                .font(.callout)
                .foregroundStyle(.white)
            
            BatteryViewModel(
                batteryLevel: batteryLevel,
                isPluggedIn: isPluggedIn,
                isCharging: isCharging,
                isInLowPowerMode: isInLowPowerMode,
                batteryWidth: batteryWidth,
                isForNotification: isForNotification
            )
        }
    }
}

#Preview {
    BatteryView(
        batteryLevel: 70,
        isCharging: true,
        isPluggedIn: true,
        isInLowPowerMode: false
    )
        .frame(width: 200, height: 200)
}
