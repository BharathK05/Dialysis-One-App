//
//  AdaptivePortionOption.swift
//  Dialysis One App
//
//  Created by user@1 on 22/01/26.
//


//
//  AdaptivePortionLibrary.swift
//  Dialysis One App
//
//  Portion options that adapt based on food type
//

import Foundation

// MARK: - Portion Options by Type

struct AdaptivePortionOption {
    let id: String
    let label: String
    let baseGrams: Double
    let icon: String
}

class AdaptivePortionLibrary {
    
    // WEIGHT portions (for rice dishes, mixed dishes)
    static let weightPortions: [AdaptivePortionOption] = [
        AdaptivePortionOption(id: "grams", label: "Grams", baseGrams: 1, icon: "⚖️"),
        AdaptivePortionOption(id: "oz", label: "Oz", baseGrams: 28.35, icon: "🔢")
    ]
    
    // COUNT portions (for breads)
    static let countPortions: [AdaptivePortionOption] = [
        AdaptivePortionOption(id: "pieces", label: "Pieces", baseGrams: 1, icon: "🔢")
    ]
    
    // BOWL portions (for curries, gravies)
    static let bowlPortions: [AdaptivePortionOption] = [
        AdaptivePortionOption(id: "small_bowl", label: "Small Bowl", baseGrams: 100, icon: "🥣"),
        AdaptivePortionOption(id: "medium_bowl", label: "Bowl", baseGrams: 150, icon: "🥣"),
        AdaptivePortionOption(id: "large_bowl", label: "Large Bowl", baseGrams: 200, icon: "🥣")
    ]
    
    // MEAL portions (fixed - full plate)
    static let mealPortions: [AdaptivePortionOption] = [
        AdaptivePortionOption(id: "meal", label: "1 Meal", baseGrams: 1, icon: "🍽️")
    ]
    
    /// Get appropriate portions for a given portion type
    static func portions(for portionType: PortionType) -> [AdaptivePortionOption] {
        switch portionType {
        case .weight:
            return weightPortions
        case .count:
            return countPortions
        case .bowl:
            return bowlPortions
        case .meal:
            return mealPortions
        }
    }
    
    /// Get quantity options for a portion type
    static func quantityOptions(for portionType: PortionType) -> [Double] {
        switch portionType {
        case .weight:
            // Grams: 50, 75, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500
            return [50, 75, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500]
            
        case .count:
            // Count: 1, 2, 3, 4, 5, 6
            return [1, 2, 3, 4, 5, 6]
            
        case .bowl:
            // Bowl multiplier: 0.5, 1, 1.5, 2
            return [0.5, 1, 1.5, 2]
            
        case .meal:
            // Meal: always 1 (fixed)
            return [1]
        }
    }
    
    /// Default portion for a type
    static func defaultPortion(for portionType: PortionType) -> AdaptivePortionOption {
        switch portionType {
        case .weight:
            return weightPortions[0] // grams
        case .count:
            return countPortions[0] // pieces
        case .bowl:
            return bowlPortions[1] // medium bowl
        case .meal:
            return mealPortions[0] // 1 meal
        }
    }
}