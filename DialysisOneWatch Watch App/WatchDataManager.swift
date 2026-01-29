//
//  WatchDataManager.swift
//  Dialysis One App
//
//  Created by user@22 on 16/12/25.
//

import Foundation
import Combine

final class WatchDataManager: NSObject, ObservableObject {
    static let shared = WatchDataManager()

    @Published var foodSummary: String?
    @Published var waterSummary: String?
    @Published var medicationSummary: String?

    @Published var medications: [WatchMedication] = []
    @Published var selectedTimeOfDay: String = "morning"

    // SUMMARY ONLY
    func applySummary(_ payload: [String: Any]) {
        if let food = payload["summary.food"] as? String {
            foodSummary = food
        }
        if let water = payload["summary.water"] as? String {
            waterSummary = water
        }
        if let med = payload["summary.medication"] as? String {
            medicationSummary = med
        }
    }

    // MEDICATION LIST
    func applyMedicationList(_ payload: [String: Any]) {
        guard let list = payload["medications"] as? [[String: Any]] else { return }

        medications = list.compactMap {
            guard
                let id = $0["id"] as? String,
                let name = $0["name"] as? String,
                let dosage = $0["dosage"] as? String,
                let isTaken = $0["isTaken"] as? Bool
            else { return nil }

            return WatchMedication(
                id: id,
                name: name,
                dosage: dosage,
                isTaken: isTaken
            )
        }
    }
}
