
//
//  Created by user@1 on 08/12/25.
//


//
//  LimitsManager.swift
//  Dialysis One App
//
//  Central place for CKD-aware daily limits.
//  NOTE: The numbers below are *demo placeholders*.
//  Please replace them with nephrologist-approved values
//  before using in a real clinical setting.
//

import Foundation

// MARK: - Data structures

struct DailyLimits {
    let potassiumMg: Int
    let sodiumMg: Int
    let proteinG: Int
    let caloriesKcal: Int
}

/// Very simple staging for now, using the label from EditHealthDetails
enum CKDStageSimple {
    case preventive
    case stage1
    case stage2
    case stage3
    case stage4
    case stage5
    
    init(fromLabel label: String?) {
        let text = (label ?? "").lowercased()
        if text.contains("stage 1") { self = .stage1 }
        else if text.contains("stage 2") { self = .stage2 }
        else if text.contains("stage 3") { self = .stage3 }
        else if text.contains("stage 4") { self = .stage4 }
        else if text.contains("stage 5") { self = .stage5 }
        else { self = .preventive }
    }
}

// MARK: - LimitsManager

final class LimitsDiet {
    
    static let shared = LimitsDiet()
    
    /// Last computed limits (used by Home + NutrientBalance + others)
    private(set) var currentLimits: DailyLimits
    
    private init() {
        // Safe-ish fallback defaults if we have no profile yet.
        currentLimits = DailyLimits(
            potassiumMg: 2500,
            sodiumMg: 1800,
            proteinG: 55,
            caloriesKcal: 1800
        )
        
        // Try to compute from any saved profile on launch.
        refreshFromSavedProfile()
    }
    
    // MARK: - Public getters used around the app
    
    func getPotassiumLimit() -> Int { currentLimits.potassiumMg }
    func getSodiumLimit()   -> Int { currentLimits.sodiumMg }
    func getProteinLimit()  -> Int { currentLimits.proteinG }
    func getCalorieLimit()  -> Int { currentLimits.caloriesKcal }
    
    // MARK: - Refresh from EditHealthDetails
    
    /// Called whenever the user updates their health details.
    /// Reads `EditHealthDetailsLocal_v1` from UserDefaults and recomputes limits.
    func refreshFromSavedProfile() {
        let defaults = UserDefaults.standard
        guard let dict = defaults.dictionary(forKey: "EditHealthDetailsLocal_v1") else {
            // nothing stored yet – keep defaults
            return
        }
        
        let stageLabel = dict["ckdStage"] as? String
        let age = dict["age"] as? Int
        let heightCm = dict["heightCm"] as? Int
        // Later: you can add weight, diabetes, labs etc here.
        
        let stage = CKDStageSimple(fromLabel: stageLabel)
        
        // 1. Start from base limits by stage
        var limits = LimitsDiet.baseLimits(for: stage)
        
        // 2. Optional light personalisation (demo only)
        if let age = age {
            // Example: gently reduce sodium for older patients
            if age > 65 {
                limits = DailyLimits(
                    potassiumMg: limits.potassiumMg,
                    sodiumMg: Int(Double(limits.sodiumMg) * 0.9),
                    proteinG: limits.proteinG,
                    caloriesKcal: limits.caloriesKcal
                )
            }
        }
        
        if let height = heightCm {
            // Rough frame-size tweak for protein (completely non-clinical demo!)
            if height > 175 {
                limits = DailyLimits(
                    potassiumMg: limits.potassiumMg,
                    sodiumMg: limits.sodiumMg,
                    proteinG: limits.proteinG + 5,
                    caloriesKcal: limits.caloriesKcal + 100
                )
            }
        }
        
        currentLimits = limits
        
        // Notify listeners (HomeDashboard, NutrientBalance, etc.)
        NotificationCenter.default.post(name: .limitsDidUpdate, object: nil)
    }
    
    // MARK: - Base tables (placeholder demo values!)
    
    private static func baseLimits(for stage: CKDStageSimple) -> DailyLimits {
        switch stage {
        case .preventive:
            // Mild conservative pattern for people at risk
            return DailyLimits(
                potassiumMg: 3200,
                sodiumMg: 2000,
                proteinG: 60,
                caloriesKcal: 1900
            )
        case .stage1, .stage2:
            return DailyLimits(
                potassiumMg: 2800,
                sodiumMg: 1800,
                proteinG: 58,
                caloriesKcal: 1850
            )
        case .stage3:
            return DailyLimits(
                potassiumMg: 2500,
                sodiumMg: 1700,
                proteinG: 55,
                caloriesKcal: 1800
            )
        case .stage4:
            return DailyLimits(
                potassiumMg: 2300,
                sodiumMg: 1600,
                proteinG: 52,
                caloriesKcal: 1750
            )
        case .stage5:
            return DailyLimits(
                potassiumMg: 2100,
                sodiumMg: 1500,
                proteinG: 50,
                caloriesKcal: 1700
            )
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    /// Fired whenever `currentLimits` changes after the user edits health details.
    static let limitsUpdate = Notification.Name("limitsDidUpdate")
}
