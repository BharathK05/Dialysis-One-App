//
//  WatchConnectivityManager.swift
//  Dialysis One App
//
//  Created by user@22 on 10/12/25.
//

import Foundation
import WatchConnectivity
import UserNotifications

final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()
    private let session: WCSession? = WCSession.isSupported() ? .default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    // Access latest context
    var latestContext: [String: Any]? {
        return session?.receivedApplicationContext
    }
    
    func notifyLogout() {
        guard let session = session else { return }

        let payload: [String: Any] = [
            "type": "auth",
            "state": "logged_out",
            "timestamp": Date().timeIntervalSince1970
        ]

        do {
            try session.updateApplicationContext(payload)
        } catch {
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            }
        }
    }

    // Evaluate payload from watch or context (incoming -> iPhone)
    func handleIncomingPayload(_ payload: [String: Any]) {
        
        // 0️⃣ AUTH payloads (sent by iPhone → Watch, ignore on iPhone)
        if payload["type"] as? String == "auth" {
            return
        }


        if payload["alert"] as? Bool == true {
            let hr = payload["heartRate"] as? Double
            let spo2 = payload["spo2"] as? Double

            NotificationEvaluator.shared.evaluate(
                heartRate: hr,
                spo2: spo2,
                timestamp: Date()
            )
            return
        }

        // 2️⃣ SUMMARY from iPhone → Watch (ignore on phone)
        if payload["type"] as? String == "summary" {
            print("Summary payload received on iPhone (ignored).")
            return
        }

        // 3️⃣ VITALS from Watch (normal flow)
        if payload["source"] as? String == "watch" {
            let hr = payload["heartRate"] as? Double
            let spo2 = payload["spo2"] as? Double
            let ts = payload["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970

            NotificationEvaluator.shared.evaluate(
                heartRate: hr,
                spo2: spo2,
                timestamp: Date(timeIntervalSince1970: ts)
            )
            return
        }

        // 4️⃣ Unknown payload (safe ignore)
        print("Unknown WC payload:", payload)
    }


    // MARK: - Sending Summary to Watch (Food, Water, Medication)
    // Canonical API used by the app:
    func sendSummary(food: String?, water: String?, medication: String?) {
        guard let session = session else { return }

        var payload: [String: Any] = [
            "type": "summary",
            "timestamp": Date().timeIntervalSince1970
        ]

        if let food = food { payload["summary.food"] = food }
        if let water = water { payload["summary.water"] = water }
        if let medication = medication { payload["summary.medication"] = medication }

        do {
            // Keeps only the most recent summary
            try session.updateApplicationContext(payload)
        } catch {
            print("updateApplicationContext failed:", error.localizedDescription)

            // fallback: immediate message if reachable
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil) { err in
                    print("sendMessage fallback failed:", err.localizedDescription)
                }
            }
        }
    }

    // ----- Compatibility overload -----
    // You were calling sendSummary(foodText:waterText:medicationText:) in many places.
    // This small overload forwards to the canonical function so you don't need to update all call sites at once.
    func sendSummary(foodText: String?, waterText: String?, medicationText: String?) {
        sendSummary(food: foodText, water: waterText, medication: medicationText)
    }
}



// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleIncomingPayload(message)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.handleIncomingPayload(applicationContext)
        }
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {

        print("WC activated on iPhone:", activationState.rawValue, error?.localizedDescription ?? "")
        NotificationCenter.default.post(name: .watchStateChanged, object: nil)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        NotificationCenter.default.post(name: .watchStateChanged, object: nil)
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        NotificationCenter.default.post(name: .watchStateChanged, object: nil)
    }

    // These two methods are required in some Xcode / SDK combos to satisfy the protocol:
    func sessionDidBecomeInactive(_ session: WCSession) {
        // no-op for now; implement if you need to handle handoff
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Must call activate on the new session after deactivation when supporting switching watches
        session.activate()
    }
}
