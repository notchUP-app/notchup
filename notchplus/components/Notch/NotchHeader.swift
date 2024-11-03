//
//  NotchHeader.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 01/11/24.
//

import SwiftUI
import Defaults

struct NotchHeader: View {
    @EnvironmentObject var viewModel: NotchViewModel
    @EnvironmentObject var batteryModel: BatteryStatusViewModel
    
    var body: some View {
        HStack {
            
            if viewModel.notchState == .open {
                Rectangle()
                    .fill(NSScreen.screens
                        .first(where: {$0.localizedName == viewModel.selectedScreen})?
                        .safeAreaInsets.top ?? 0 > 0 ? .black : .clear
                    )
                    .frame(width: Sizes().size.closed.width! - 5)
                    .mask { NotchShape() }
                    .shadow(color: .black, radius: 30, x: -25, y: 10)
                    .zIndex(1)
            }
            
            
            HStack {
                if viewModel.notchState == .open {
                    if Defaults[.settingsIconInNotch] {
                        SettingsLink(label: {
                            Capsule()
                                .fill(.black)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Image(systemName: "gear")
                                        .foregroundColor(.white)
                                        .padding()
                                        .imageScale(.medium)
                                }
                        })
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if Defaults[.showBattery] {
                        BatteryView(
                            batteryLevel: batteryModel.batteryLevel,
                            isPluggedIn: batteryModel.isPluggedIn,
                            batteryWidth: 30
                        )
                    }
                }
            }
            .font(.system(.headline, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .opacity(viewModel.notchState == .closed ? 0 : 1)
            .blur(radius: viewModel.notchState == .closed ? 20 : 0)
            .animation(.smooth.delay(0.2), value: viewModel.notchState)
            .zIndex(2)
        }
        .foregroundColor(.gray)
        .environmentObject(viewModel)
    }
}

#Preview {
    NotchHeader()
        .environmentObject(NotchViewModel())
        .environmentObject(BatteryStatusViewModel(viewModel: NotchViewModel()))
}

