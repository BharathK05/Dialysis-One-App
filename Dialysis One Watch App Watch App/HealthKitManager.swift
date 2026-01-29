//
//  HealthKitManager.swift
//  Dialysis One App
//
//  Created by user@22 on 15/12/25.
//

import Foundation
import HealthKit
import Combine

final class HealthKitManager: ObservableObject {

    static let shared = HealthKitManager()

    @Published var heartRate: Double?
    @Published var oxygenSaturation: Double?
    @Published var statusMessage: String = "Waiting for workout…"

    private let healthStore = HKHealthStore()

    // Thresholds
    private let HR_HIGH: Double = 120
    private let HR_LOW: Double = 40
    private let SPO2_LOW: Double = 92

    private var lastAlertTimes: [String: Date] = [:]
    private let cooldown: TimeInterval = 5 * 60

    private init() {}

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Health data unavailable"
            return
        }

        let types: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        ]

        healthStore.requestAuthorization(toShare: [], read: types) { [weak self] ok, err in
            DispatchQueue.main.async {
                if ok {
                    self?.statusMessage = "Live vitals active"
                    WorkoutManager.shared.start()
                } else {
                    self?.statusMessage = err?.localizedDescription ?? "Permission denied"
                }
            }
        }
    }

    func updateHeartRate(_ value: Double) {
        heartRate = value
        sendVitals()
        checkAlerts()
    }

    func updateSpO2(_ value: Double) {
        oxygenSaturation = value
        sendVitals()
        checkAlerts()
    }

    private func sendVitals() {
        WatchConnectivityManager.shared.sendVitals(
            heartRate: heartRate,
            spo2: oxygenSaturation
        )
    }

    private func checkAlerts() {
        if let hr = heartRate,
           (hr > HR_HIGH || hr < HR_LOW),
           shouldAlert("hr") {

            WatchConnectivityManager.shared.sendImmediateAlert(
                heartRate: hr,
                spo2: oxygenSaturation,
                details: "Heart rate \(Int(hr)) bpm"
            )
        }

        if let s = oxygenSaturation,
           s < SPO2_LOW,
           shouldAlert("spo2") {

            WatchConnectivityManager.shared.sendImmediateAlert(
                heartRate: heartRate,
                spo2: s,
                details: "SpO₂ \(Int(s))%"
            )
        }
    }

    private func shouldAlert(_ key: String) -> Bool {
        let now = Date()
        if let last = lastAlertTimes[key],
           now.timeIntervalSince(last) < cooldown {
            return false
        }
        lastAlertTimes[key] = now
        return true
    }

    func stop() {
        heartRate = nil
        oxygenSaturation = nil
        statusMessage = "Stopped"
    }
}
