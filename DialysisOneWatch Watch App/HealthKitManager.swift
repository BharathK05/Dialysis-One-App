//
//  HealthKitManager.swift
//  Dialysis One App
//
//  Created by user@22 on 16/12/25.
//


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

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Health data unavailable"
            completion(false)
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        ]

        let shareTypes: Set<HKSampleType> = [
            HKObjectType.workoutType() // ⭐ REQUIRED
        ]

        healthStore.requestAuthorization(
            toShare: shareTypes,
            read: readTypes
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.statusMessage = "Live vitals active"
                    completion(true)
                } else {
                    print("❌ HealthKit auth failed:", error?.localizedDescription ?? "")
                    self?.statusMessage = "Permission denied"
                    completion(false)
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
