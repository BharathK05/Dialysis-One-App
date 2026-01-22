//
//  WatchDataManager.swift
//  Dialysis One App
//
//  Created by user@22 on 15/12/25.
//


import Foundation
import WatchConnectivity
import Combine

final class WatchDataManager: NSObject, ObservableObject {
    static let shared = WatchDataManager()

    @Published var foodSummary: String? = nil
    @Published var waterSummary: String? = nil
    @Published var medicationSummary: String? = nil

    private let session: WCSession? = WCSession.isSupported() ? .default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    private func applyContext(_ context: [String: Any]) {
        // Using keys we set on iOS
        DispatchQueue.main.async {
            if let food = context["summary.food"] as? String { self.foodSummary = food }
            if let water = context["summary.water"] as? String { self.waterSummary = water }
            if let med = context["summary.medication"] as? String { self.medicationSummary = med }
        }
    }
}

extension WatchDataManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // When the session activates, there may be a previously-sent applicationContext available:
        if let ctx = session.receivedApplicationContext as? [String: Any] {
            applyContext(ctx)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        applyContext(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // fallback immediate messages (if you use sendMessage on phone)
        applyContext(message)
    }

    #if os(watchOS)
    // not required on watch side, but keep empty stubs to satisfy protocol
    func sessionReachabilityDidChange(_ session: WCSession) {
        // if needed, react to reachability
    }
    #endif
}
