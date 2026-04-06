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
    
    // Recent food names for suggestions on Watch diet input
    @Published var recentFoodNames: [String] = []
    
    // Nutrition lookup result from iPhone (for Watch diet flow)
    @Published var pendingNutritionResult: WatchNutritionResult?
    @Published var nutritionLookupError: String?
    @Published var isLookingUpNutrition: Bool = false

    private let defaults = UserDefaults.standard
    
    private override init() {
        super.init()
        loadFromDefaults()
    }
    
    // MARK: - Persistence (survive app restart on Watch)
    
    private func loadFromDefaults() {
        foodSummary = defaults.string(forKey: "watch.foodSummary")
        waterSummary = defaults.string(forKey: "watch.waterSummary")
        medicationSummary = defaults.string(forKey: "watch.medicationSummary")
        recentFoodNames = defaults.stringArray(forKey: "watch.recentFoodNames") ?? []
    }
    
    private func saveToDefaults() {
        defaults.set(foodSummary, forKey: "watch.foodSummary")
        defaults.set(waterSummary, forKey: "watch.waterSummary")
        defaults.set(medicationSummary, forKey: "watch.medicationSummary")
        defaults.set(recentFoodNames, forKey: "watch.recentFoodNames")
    }

    // SUMMARY ONLY (partial update)
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
        saveToDefaults()
    }
    
    // FULL SYNC (all data at once from iPhone)
    func applyFullSync(_ payload: [String: Any]) {
        if let food = payload["summary.food"] as? String {
            foodSummary = food
        }
        if let water = payload["summary.water"] as? String {
            waterSummary = water
        }
        if let med = payload["summary.medication"] as? String {
            medicationSummary = med
        }
        
        // Recent food names for diet suggestions
        if let foods = payload["recentFoods"] as? [String] {
            recentFoodNames = foods
        }
        
        // Medication list if included
        if let list = payload["medications"] as? [[String: Any]] {
            applyMedicationListData(list)
        }
        
        saveToDefaults()
    }

    // MEDICATION LIST
    func applyMedicationList(_ payload: [String: Any]) {
        guard let list = payload["medications"] as? [[String: Any]] else { return }
        applyMedicationListData(list)
    }
    
    private func applyMedicationListData(_ list: [[String: Any]]) {
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
    
    // MARK: - Add recent food name
    func addRecentFood(_ name: String) {
        // Keep recent list unique and max 20
        recentFoodNames.removeAll { $0.lowercased() == name.lowercased() }
        recentFoodNames.insert(name, at: 0)
        if recentFoodNames.count > 20 {
            recentFoodNames = Array(recentFoodNames.prefix(20))
        }
        saveToDefaults()
    }
}
