//
//  BatteryViewModel.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 21/10/24.
//

import SwiftUI
import IOKit.ps
import Defaults

class BatteryStatusViewModel: ObservableObject {

    private var wasCharging: Bool = false
    private var powerSourceChangedCallback: IOPowerSourceCallbackType?
    private var runLoopSource: Unmanaged<CFRunLoopSource>?

    @ObservedObject var coordinator = NotchViewCoordinator.shared

    @Published private(set) var batteryLevel: Float = 0.0
    @Published private(set) var maxCapacity: Float = 0.0
    @Published private(set) var isPluggedIn: Bool = false
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var isInLowPowerMode: Bool = false
    @Published private(set) var isInitial: Bool = false
    @Published private(set) var timeRemaining: Int = 0
    @Published private(set) var statusText: String = ""

    private let batteryManager = BatteryActivityManager.shared
    private var batteryManagerId: Int?

    static let shared = BatteryStatusViewModel()

    deinit {
        Logger.log("Cleaning up battering monitor", type: .debug)
        if let batteryManagerId: Int = batteryManagerId {
            batteryManager.removeObserver(byId: batteryManagerId)
        }
    }

    init() {
        setupPowerStatus()
        setupMonitor()
    }

    private func handleBatteryEvent(_ event: BatteryEvent) {
        switch event {
        case .powerSourceChanged(let isPluggedIn):
            Logger.log("Power source: \(isPluggedIn ? "Connected" : "Disconnected")", type: .battery)
            withAnimation {
                self.isPluggedIn = isPluggedIn
                self.statusText = isPluggedIn ? "Plugged In" : "Unplugged"
            }
        case .batteryLevelChanged(let level):
            Logger.log("Battery level: \(level)", type: .battery)
            withAnimation {
                self.batteryLevel = level
            }
        case .lowPowerModeChanged(let isEnabled):
            Logger.log("Low power mode: \(isEnabled ? "Enabled" : "Disabled")", type: .battery)
            withAnimation {
                self.isInLowPowerMode = isEnabled
                self.statusText = "Low Power: \(isEnabled ? "On" : "Off")"
            }

        case .isChargingChanged(let isCharging):
            Logger.log("Charging: \(isCharging ? "Yes" : "No")", type: .battery)
            Logger.log("Max Capacity: \(self.maxCapacity)", type: .battery)
            Logger.log("Battery Level: \(self.batteryLevel)", type: .battery)
            withAnimation {
                self.isCharging = isCharging
                self.statusText = isCharging ? "Charging battery" : (self.batteryLevel < self.maxCapacity ? "Not charging" : "Battery full")
            }

        case .timeRemainingChanged(let time):
            Logger.log("Time remaining: \(time)", type: .battery)
            withAnimation {
                self.timeRemaining = time
            }
        case .maxCapacityChanged(let capacity):
            Logger.log("Max capacity: \(capacity)", type: .battery)
            withAnimation {
                self.maxCapacity = capacity
            }
        case .error(let description):
            Logger.log("Error: \(description)", type: .error)
        }
    }

    private func updateBatteryInfo(_ batteryInfo: BatteryInfo) {
        withAnimation {
            self.batteryLevel = batteryInfo.currentCapacity
            self.maxCapacity = batteryInfo.maxCapacity
            self.isPluggedIn = batteryInfo.isPluggedIn
            self.isCharging = batteryInfo.isCharging
            self.timeRemaining = batteryInfo.timeRemaining
            self.isInLowPowerMode = batteryInfo.isInLowPowerMode
            self.statusText = batteryInfo.isPluggedIn ? "Plugged In" : "Unplugged"
        }

        withAnimation {
            if self.isCharging {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.statusText = "Charging: Yes"
                }
            }
            if self.isInLowPowerMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.statusText = "Low Power: On"
                }
            }
        }
    }

    private func setupMonitor() {
        batteryManagerId = batteryManager.addObserver { [weak self] event in
            guard let self = self else { return }
            self.handleBatteryEvent(event)
        }
    }

    private func setupPowerStatus() {
        let batteryInfo = batteryManager.initializeBatteryInfo()
        updateBatteryInfo(batteryInfo)
    }
}
