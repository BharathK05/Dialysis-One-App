//
//  HealthKitManager.swift
//  Dialysis One App
//
//  Created by user@22 on 15/12/25.
//

import Foundation
import HealthKit
import Combine

final class HealthKitManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var heartRate: Double?
    @Published var oxygenSaturation: Double?
    @Published var statusMessage: String = "Requesting HealthKit access..."
    
    // MARK: - Alert thresholds & cooldown (tune these values)
    private let HR_HIGH_THRESHOLD: Double = 120.0
    private let HR_LOW_THRESHOLD: Double  = 40.0
    private let SPO2_LOW_THRESHOLD: Double = 92.0

    // Simple cooldown so we don't spam alerts repeatedly
    private var lastAlertTimes: [String: Date] = [:]
    private let alertCooldown: TimeInterval = 5 * 60 // 5 minutes
    
    // MARK: - Health Types
    
    private var heartRateType: HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .heartRate)!
    }
    
    private var oxygenType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)
    }
    
    override init() {
        super.init()
        // If you want connectivity to start as soon as manager is instantiated,
        // ensure WatchConnectivityManager.shared is initialized from App init.
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Health data not available."
            return
        }
        
        var typesToShare: Set<HKSampleType> = []
        var typesToRead: Set<HKObjectType> = [heartRateType]
        
        if let oxygenType = oxygenType {
            typesToRead.insert(oxygenType)
        }
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusMessage = "Auth error: \(error.localizedDescription)"
                } else if success {
                    self?.statusMessage = "Authorized. Starting live data..."
                } else {
                    self?.statusMessage = "Authorization not granted."
                }
            }
        }
    }
    
    func stopStreaming() {
        // no-op, WorkoutManager owns the workout
    }


    
    // MARK: - Alert cooldown helper
    
    private func shouldSendAlert(for key: String) -> Bool {
        let now = Date()
        if let last = lastAlertTimes[key], now.timeIntervalSince(last) < alertCooldown {
            return false
        }
        lastAlertTimes[key] = now
        return true
    }
    
    // MARK: - Statistics handler
    
    private func handleStatistics(_ statistics: HKStatistics) {
        // quantityType is already HKQuantityType?
        let quantityType = statistics.quantityType
            guard let quantity = statistics.mostRecentQuantity() else { return }
        
        DispatchQueue.main.async {
            switch quantityType {
            case self.heartRateType:
                let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = quantity.doubleValue(for: bpmUnit)
                self.heartRate = value
                self.statusMessage = "Live heart rate updated."
                
                // Send updated vitals to iPhone
                WatchConnectivityManager.shared.sendVitals(heartRate: self.heartRate, spo2: self.oxygenSaturation)
                
                // Abnormal detection with cooldown
                if let hr = self.heartRate {
                    if hr >= self.HR_HIGH_THRESHOLD || hr <= self.HR_LOW_THRESHOLD {
                        if self.shouldSendAlert(for: "hr") {
                            let details = "Heart rate \(Int(hr)) bpm"
                            WatchConnectivityManager.shared.sendImmediateAlert(heartRate: hr,
                                                                              spo2: self.oxygenSaturation,
                                                                              details: details)
                            // Optionally post a local notification on watch here
                        }
                    }
                }
                
            case self.oxygenType:
                // Oxygen saturation is a percentage (0.0 - 1.0)
                let percentUnit = HKUnit.percent()
                let value = quantity.doubleValue(for: percentUnit) * 100.0
                self.oxygenSaturation = value
                self.statusMessage = "Live oxygen updated."
                
                // Send updated vitals to iPhone
                WatchConnectivityManager.shared.sendVitals(heartRate: self.heartRate, spo2: self.oxygenSaturation)
                
                // Abnormal detection for SpO2 with cooldown
                if let spo2 = self.oxygenSaturation {
                    if spo2 <= self.SPO2_LOW_THRESHOLD {
                        if self.shouldSendAlert(for: "spo2") {
                            let details = "SpO₂ \(Int(spo2))%"
                            WatchConnectivityManager.shared.sendImmediateAlert(heartRate: self.heartRate,
                                                                              spo2: spo2,
                                                                              details: details)
                            // Optionally post a local notification on watch here
                        }
                    }
                }
                
            default:
                break
            }
        }
    }
}

// MARK: - HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate

extension HealthKitManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.statusMessage = "Workout session state: \(toState.rawValue)"
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.statusMessage = "Workout error: \(error.localizedDescription)"
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Not used, but required by protocol
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for sampleType in collectedTypes {
            guard let quantityType = sampleType as? HKQuantityType else { continue }
            
            if let statistics = workoutBuilder.statistics(for: quantityType) {
                handleStatistics(statistics)
            }
        }
    }
}
