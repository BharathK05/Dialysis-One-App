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

    func applySummary(_ context: [String: Any]) {
        if let food = context["summary.food"] as? String {
            foodSummary = food
        }
        if let water = context["summary.water"] as? String {
            waterSummary = water
        }
        if let med = context["summary.medication"] as? String {
            medicationSummary = med
        }
    }

}
