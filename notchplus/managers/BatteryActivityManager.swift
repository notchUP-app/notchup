//
//  BatteryActivityManager.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 22/04/25.
//

import Foundation
import IOKit.ps

struct BatteryInfo {
    var isPluggedIn: Bool
    var isCharging: Bool
    var currentCapacity: Float
    var maxCapacity: Float
    var isInLowPowerMode: Bool
    var timeRemaining: Int
}

class BatteryActivityManager {
    static let shared = BatteryActivityManager()

    var onBatteryLevelChange: ((Float) -> Void)?
    var onMaxCapacityChange: ((Float) -> Void)?
    var onPowerModeChange: ((Bool) -> Void)?
    var onPowerSourceChange: ((Bool) -> Void)?
    var onChargingStateChange: ((Bool) -> Void)?
    var onTimeRemainingChange: ((Int) -> Void)?

    private var batterySource: CFRunLoopSource?
    private var observers: [(BatteryEvent) -> Void] = []
    private var previousBatteryInfo: BatteryInfo?
    private var notificationQueue: [BatteryEvent] = []
    private var isProcessingNotifications = false

    private let defaultBatteryInfo = BatteryInfo(
        isPluggedIn: false,
        isCharging: false,
        currentCapacity: 0,
        maxCapacity: 0,
        isInLowPowerMode: false,
        timeRemaining: 0
    )

    private init() {
        startMonitoring()
        setupLowPowerModeObserver()
    }

    private func setupLowPowerModeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(lowPowerModeChanged),
            name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }

    func addObserver(_ observer: @escaping (BatteryEvent) ->  Void) -> Int {
        observers.append(observer)
        return observers.count - 1
    }

    func removeObserver(byId id: Int) {
        guard id >= 0 && id < observers.count else { return }
        observers.remove(at: id)
    }

    private func notifyObservers(event: BatteryEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for observer in self.observers {
                observer(event)
            }
        }
    }

    private func processNextNotification() {
        guard !isProcessingNotifications, !notificationQueue.isEmpty else { return }
        isProcessingNotifications = true

        let event = notificationQueue.removeFirst()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.notifyObservers(event: event)
            self.isProcessingNotifications = false

            if !self.notificationQueue.isEmpty {
                self.processNextNotification()
            }
        }
    }

    private func enqueueNotification(_ event: BatteryEvent) {
        notificationQueue.append(event)
        processNextNotification()
    }

    private func checkAndNotify<T: Equatable>(
        previous: T,
        current: T,
        eventGenerator: (T) -> BatteryEvent
    ) {
        if previous != current {
            enqueueNotification(eventGenerator(current))
        }
    }

    private func getBatteryInfo() -> BatteryInfo {
        do {
            guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
                throw BatteryError.powerSourceUnavailable
            }

            guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
                !sources.isEmpty else {
                throw BatteryError.batteryInfoUnavailable("No power sources available")
            }

            let source = sources.first!

            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                throw BatteryError.batteryInfoUnavailable("Failed to get power source description")
            }

            guard let currentCapacity = description[kIOPSCurrentCapacityKey] as? Float else {
                throw BatteryError.batteryParameterMissing("Current capacity")
            }

            guard let maxCapacity = description[kIOPSMaxCapacityKey] as? Float else {
                throw BatteryError.batteryParameterMissing("Max capacity")
            }

            guard let isCharging = description["Is Charging"] as? Bool else {
                throw BatteryError.batteryParameterMissing("Charging state")
            }

            guard let powerSource = description[kIOPSPowerSourceStateKey] as? String else {
                throw BatteryError.batteryParameterMissing("Power source state")
            }


            var batteryInfo = BatteryInfo(
                isPluggedIn: powerSource == kIOPSACPowerValue,
                isCharging: isCharging,
                currentCapacity: currentCapacity,
                maxCapacity: maxCapacity,
                isInLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
                timeRemaining: 0
            )

            if let timeRemaining = description[kIOPSTimeToFullChargeKey] as? Int {
                batteryInfo.timeRemaining = timeRemaining
            }

            return batteryInfo
        } catch BatteryError.powerSourceUnavailable {
            Logger.log("Power source information unavailable", type: .error)
            return defaultBatteryInfo
        } catch BatteryError.batteryInfoUnavailable(let reason) {
            Logger.log("Battery info unavailable: \(reason)", type: .error)
            return defaultBatteryInfo
        } catch BatteryError.batteryParameterMissing(let parameter) {
            Logger.log("Battery parameter missing: \(parameter)", type: .error)
            return defaultBatteryInfo
        } catch {
            Logger.log("Unknown error: \(error.localizedDescription)", type: .error)
            return defaultBatteryInfo
        }
    }

    private func notifyBatteryChanges() {
        let batteryInfo = getBatteryInfo()

        if let previousInfo = previousBatteryInfo {
            checkAndNotify(
                previous: previousInfo.isPluggedIn,
                current: batteryInfo.isPluggedIn,
                eventGenerator: { .powerSourceChanged(isPluggedIn: $0) }
            )
            
            checkAndNotify(
                previous: previousInfo.currentCapacity,
                current: batteryInfo.currentCapacity,
                eventGenerator: { .batteryLevelChanged(level: $0) }
            )

            checkAndNotify(
                previous: previousInfo.isCharging,
                current: batteryInfo.isCharging,
                eventGenerator: { .isChargingChanged(isCharging: $0) }
            )
            
            checkAndNotify(
                previous: previousInfo.isInLowPowerMode,
                current: batteryInfo.isInLowPowerMode,
                eventGenerator: { .lowPowerModeChanged(isEnabled: $0) }
            )

            checkAndNotify(
                previous: previousInfo.timeRemaining,
                current: batteryInfo.timeRemaining,
                eventGenerator: { .timeRemainingChanged(time: $0) }
            )
            
            checkAndNotify(
                previous: previousInfo.maxCapacity,
                current: batteryInfo.maxCapacity,
                eventGenerator: { .maxCapacityChanged(capacity: $0) }
            )
        } else {
            enqueueNotification(.powerSourceChanged(isPluggedIn: batteryInfo.isPluggedIn))
            enqueueNotification(.batteryLevelChanged(level: batteryInfo.currentCapacity))
            enqueueNotification(.isChargingChanged(isCharging: batteryInfo.isCharging))
            enqueueNotification(.lowPowerModeChanged(isEnabled: batteryInfo.isInLowPowerMode))
            enqueueNotification(.timeRemainingChanged(time: batteryInfo.timeRemaining))
            enqueueNotification(.maxCapacityChanged(capacity: batteryInfo.maxCapacity))
        }

        previousBatteryInfo = batteryInfo

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onBatteryLevelChange?(batteryInfo.currentCapacity)
            self.onPowerSourceChange?(batteryInfo.isPluggedIn)
            self.onChargingStateChange?(batteryInfo.isCharging)
            self.onPowerModeChange?(batteryInfo.isInLowPowerMode)
            self.onTimeRemainingChange?(batteryInfo.timeRemaining)
            self.onMaxCapacityChange?(batteryInfo.maxCapacity)
        }
    }

    func initializeBatteryInfo() -> BatteryInfo {
        previousBatteryInfo = getBatteryInfo()
        guard let batteryInfo = previousBatteryInfo else {
            return BatteryInfo(
                isPluggedIn: false,
                isCharging: false,
                currentCapacity: 0,
                maxCapacity: 0,
                isInLowPowerMode: false,
                timeRemaining: 0
            )
        }

        return batteryInfo
    }

    private func startMonitoring() {
        guard let powerSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let manager = Unmanaged<BatteryActivityManager>.fromOpaque(context).takeUnretainedValue()
            manager.notifyBatteryChanges()
        }, Unmanaged.passUnretained(self).toOpaque())?.takeRetainedValue() else {
            return
        }

        batterySource = powerSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), powerSource, .defaultMode)
    }

    private func stopMonitoring() {
        if let powerSource = batterySource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), powerSource, .defaultMode)
            batterySource = nil
        }
    }

    @objc private func lowPowerModeChanged() {
        notifyBatteryChanges()
    }

    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
}
