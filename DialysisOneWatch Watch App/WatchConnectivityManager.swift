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

        // 📊 Summary payload (Food / Water / Medication)
        if payload["type"] as? String == "summary" {

            DispatchQueue.main.async {
                WatchDataManager.shared.applySummary(payload)
            }
            return
        }
        
        if payload["type"] as? String == "medication_list" {
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
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("⌚️ WC activated:", activationState.rawValue, error?.localizedDescription ?? "")
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
