//
//  WatchConnectivityManager.swift
//  Dialysis One App
//
//  Created by user@22 on 16/12/25.
//


//  WatchConnectivityManagerWatch.swift
//  Dialysis One Watch App
//
//  Created by user@22 on 15/12/25.
//

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject {

    static let shared = WatchConnectivityManager()
    private let session: WCSession? = WCSession.isSupported() ? .default : nil

    private override init() {
        super.init()

        guard let session = session else { return }

        session.delegate = self
        session.activate()

        print("⌚️ WC init — activated. Reachable:", session.isReachable)
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("⌚️ Reachable:", session.isReachable)
        // When we become reachable, request fresh data from iPhone
        if session.isReachable {
            requestSync()
        }
    }

    // MARK: - Request Sync from iPhone
    
    func requestSync() {
        guard let session = session, session.isReachable else { return }
        
        let payload: [String: Any] = [
            "type": WatchMessageType.requestSync.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(payload, replyHandler: nil) { err in
            print("⌚️ requestSync failed:", err.localizedDescription)
        }
        
        print("⌚️ Requested sync from iPhone")
    }

    // MARK: - Send Vitals (Watch → iPhone)

    func sendVitals(heartRate: Double?, spo2: Double?) {
        guard let session = session else { return }

        var payload: [String: Any] = [
            "source": "watch",
            "timestamp": Date().timeIntervalSince1970
        ]

        if let hr = heartRate { payload["heartRate"] = hr }
        if let s = spo2 { payload["spo2"] = s }

        do {
            try session.updateApplicationContext(payload)
        } catch {
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil) { err in
                    print("❌ sendVitals failed:", err.localizedDescription)
                }
            }
        }
    }
    
    func sendAddWater(type: String, quantity: Int) {
        guard let session = session else { return }

        let payload: [String: Any] = [
            "type": WatchMessageType.addWater.rawValue,
            "fluidType": type,
            "quantity": quantity,
            "timestamp": Date().timeIntervalSince1970
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil)
        } else {
            try? session.updateApplicationContext(payload)
        }
    }
    
    func sendAddMedication(medicationId: String, timeOfDay: String) {
        guard let session = session else { return }

        let payload: [String: Any] = [
            "type": WatchMessageType.addMedication.rawValue,
            "medicationId": medicationId,
            "timeOfDay": timeOfDay,
            "timestamp": Date().timeIntervalSince1970
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil)
        } else {
            try? session.updateApplicationContext(payload)
        }
    }
    
    // MARK: - Send Diet Entry (Watch → iPhone)
    
    func sendAddDiet(
        foodName: String,
        quantity: Int,
        mealType: String,
        calories: Int,
        protein: Double,
        potassium: Int,
        sodium: Int
    ) {
        guard let session = session else { return }
        
        let payload: [String: Any] = [
            "type": WatchMessageType.addDiet.rawValue,
            "foodName": foodName,
            "quantity": quantity,
            "mealType": mealType,
            "calories": calories,
            "protein": protein,
            "potassium": potassium,
            "sodium": sodium,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil)
        } else {
            try? session.updateApplicationContext(payload)
        }
    }
    
    // MARK: - Nutrition Lookup (Watch → iPhone → Watch)
    
    func requestNutritionLookup(foodName: String) {
        guard let session = session else {
            DispatchQueue.main.async {
                WatchDataManager.shared.isLookingUpNutrition = false
                WatchDataManager.shared.nutritionLookupError = "Watch session unavailable"
            }
            return
        }
        
        guard session.isReachable else {
            DispatchQueue.main.async {
                WatchDataManager.shared.isLookingUpNutrition = false
                WatchDataManager.shared.nutritionLookupError = "iPhone not reachable"
            }
            return
        }
        
        DispatchQueue.main.async {
            WatchDataManager.shared.isLookingUpNutrition = true
            WatchDataManager.shared.nutritionLookupError = nil
            WatchDataManager.shared.pendingNutritionResult = nil
        }
        
        let payload: [String: Any] = [
            "type": WatchMessageType.nutritionLookup.rawValue,
            "foodName": foodName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(payload, replyHandler: { reply in
            // iPhone replied with nutrition data
            DispatchQueue.main.async {
                WatchDataManager.shared.isLookingUpNutrition = false
                
                if let error = reply["error"] as? String {
                    WatchDataManager.shared.nutritionLookupError = error
                    return
                }
                
                if let result = WatchNutritionResult.from(reply) {
                    WatchDataManager.shared.pendingNutritionResult = result
                    print("⌚️ Nutrition received: \(result.foodName) — \(result.caloriesPer100g) kcal/100g")
                } else {
                    WatchDataManager.shared.nutritionLookupError = "Invalid nutrition data"
                }
            }
        }, errorHandler: { error in
            DispatchQueue.main.async {
                WatchDataManager.shared.isLookingUpNutrition = false
                WatchDataManager.shared.nutritionLookupError = "Lookup failed: \(error.localizedDescription)"
            }
            print("⌚️ Nutrition lookup error:", error.localizedDescription)
        })
    }


    // MARK: - Immediate Alerts (Watch → iPhone)

    func sendImmediateAlert(heartRate: Double?, spo2: Double?, details: String) {
        guard let session = session, session.isReachable else { return }

        var payload: [String: Any] = [
            "alert": true,
            "details": details,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let hr = heartRate { payload["heartRate"] = hr }
        if let s = spo2 { payload["spo2"] = s }

        session.sendMessage(payload, replyHandler: nil) { error in
            print("❌ alert send failed:", error.localizedDescription)
        }
    }

    // MARK: - Incoming Payloads (iPhone → Watch)

    private func handleIncomingPayload(_ payload: [String: Any]) {

        // 🔐 Logout from iPhone
        if payload["type"] as? String == "auth",
           payload["state"] as? String == "logged_out" {

            DispatchQueue.main.async {
                AppState.shared.handleLogout()
            }
            return
        }
        
        // 🔐 Login from iPhone
        if payload["type"] as? String == "auth",
           payload["state"] as? String == "logged_in" {
            DispatchQueue.main.async {
                AppState.shared.handleLogin()
            }
            return
        }

        // 📊 Summary payload (Food / Water / Medication)
        if payload["type"] as? String == WatchMessageType.summary.rawValue {

            DispatchQueue.main.async {
                WatchDataManager.shared.applySummary(payload)
            }
            return
        }
        
        // 📊 Full sync (all data at once)
        if payload["type"] as? String == WatchMessageType.fullSync.rawValue {
            DispatchQueue.main.async {
                WatchDataManager.shared.applyFullSync(payload)
            }
            return
        }
        
        // 🍽️ Nutrition result (async fallback from iPhone)
        if payload["type"] as? String == WatchMessageType.nutritionResult.rawValue {
            DispatchQueue.main.async {
                WatchDataManager.shared.isLookingUpNutrition = false
                if let result = WatchNutritionResult.from(payload) {
                    WatchDataManager.shared.pendingNutritionResult = result
                } else {
                    WatchDataManager.shared.nutritionLookupError = "Invalid nutrition data"
                }
            }
            return
        }
        
        if payload["type"] as? String == WatchMessageType.medicationList.rawValue {
            DispatchQueue.main.async {
                WatchDataManager.shared.applyMedicationList(payload)
            }
            return
        }

    }

}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String : Any]) {
        handleIncomingPayload(applicationContext)
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {
        handleIncomingPayload(message)
    }
    
    func session(_ session: WCSession,
                 didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncomingPayload(userInfo)
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("⌚️ WC activated:", activationState.rawValue, error?.localizedDescription ?? "")
        
        // Request fresh data on activation
        if activationState == .activated {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestSync()
            }
        }
    }
    
    // ADD THESE FOR iOS:
        #if os(iOS)
        func sessionDidBecomeInactive(_ session: WCSession) {
            print("📱 WC became inactive")
        }
        
        func sessionDidDeactivate(_ session: WCSession) {
            print("📱 WC deactivated, reactivating...")
            session.activate()
        }
        #endif
}
