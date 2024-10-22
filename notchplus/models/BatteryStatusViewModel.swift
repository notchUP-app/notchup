//
//  BatteryStatusViewModel.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 21/10/24.
//

import SwiftUI
import IOKit.ps
import Defaults

class BatteryStatusViewModel: ObservableObject {
    private var viewModel: NotchViewModel
    
    @Published var batteryLevel: Float = 0.0
    @Published var isPluggedIn: Bool = false
    @Published var showChargingInfo: Bool = false
    
    private var powerSourceChangedCallback: IOPowerSourceCallbackType?
    private var runLoopSource: Unmanaged<CFRunLoopSource>?
    var animations: NotchAnimations = NotchAnimations()
    
    deinit {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource.takeUnretainedValue(), .defaultMode)
            runLoopSource.release()
        }
    }
    
    init(viewModel: NotchViewModel) {
        self.viewModel = viewModel
        
        updateBatteryStatus()
        startMonitoring()
    }
    
    private func updateBatteryStatus() {
        print("collecting battery status")
        
        if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] {
            for source in sources {
                if let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: AnyObject],
                   let currentCapacity = info[kIOPSCurrentCapacityKey] as? Int,
                   let maxCapacity = info[kIOPSMaxCapacityKey] as? Int,
                   let isCharging = info["Is Charging"] as? Bool {
                    
                    print("is charging: \(isCharging)")
                    print("current capacity \(currentCapacity)")
                    
                    if (Defaults[.chargingInfoAllowed] ){
                        withAnimation {
                            self.batteryLevel = Float((currentCapacity * 100) / maxCapacity)
                        }
                        
                        if (isCharging && !self.isPluggedIn) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + (viewModel.firstLaunch ? 6 : 0)) {
                                self.viewModel.toggleExpandingView(status: true, type: .battery)
                                self.showChargingInfo = true
                                self.isPluggedIn = true
                            }
                        }
                        
                        withAnimation {
                            self.isPluggedIn = isCharging
                        }
                        
                    }
                }
            }
        }
    }
    
    private func startMonitoring() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        powerSourceChangedCallback = { context in
            if let context = context {
                let _self = Unmanaged<BatteryStatusViewModel>.fromOpaque(context).takeUnretainedValue()
                
                DispatchQueue.main.async {
                    _self.updateBatteryStatus()
                }
            }
        }
        
        if let runLoopSource = IOPSNotificationCreateRunLoopSource(powerSourceChangedCallback!, context)?.takeRetainedValue() {
            self.runLoopSource = Unmanaged<CFRunLoopSource>.passRetained(runLoopSource)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        }
    }
    
}
