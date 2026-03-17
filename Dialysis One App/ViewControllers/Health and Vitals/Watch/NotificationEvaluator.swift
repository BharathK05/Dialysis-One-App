//
//  NotificationEvaluator.swift
//  Dialysis One App
//
//  Created by user@22 on 10/12/25.
//


import Foundation

final class NotificationEvaluator {
    static let shared = NotificationEvaluator()

    // Example thresholds — tune these to your clinical needs
    private let hrHigh = 120.0
    private let hrLow = 40.0
    private let spo2Low = 92.0
    
    private var lastAlertTimes: [String: Date] = [:]
    private let alertCooldown: TimeInterval = 5 * 60 // 5 minutes

    private init() {}

    func evaluate(heartRate: Double?, spo2: Double?, timestamp: Date) {
        var alerts: [String] = []

        if let hr = heartRate {
            if hr >= hrHigh {
                if shouldAlert(key: "hrHigh") {
                    alerts.append("High heart rate: \(Int(hr)) bpm")
                }
            } else if hr <= hrLow {
                if shouldAlert(key: "hrLow") {
                    alerts.append("Low heart rate: \(Int(hr)) bpm")
                }
            }
        }

        if let s = spo2 {
            if s <= spo2Low {
                if shouldAlert(key: "spo2Low") {
                    alerts.append("Low oxygen saturation: \(Int(s))%")
                }
            }
        }

        guard !alerts.isEmpty else { return }

        let title = "DialysisOne — Vitals alert"
        let body = alerts.joined(separator: " • ")

        NotificationManager.shared.postAlert(title: title, body: body)
    }

    
    private func shouldAlert(key: String) -> Bool {
        if let last = lastAlertTimes[key], Date().timeIntervalSince(last) < alertCooldown { return false }
        lastAlertTimes[key] = Date()
        return true
    }
}
