//
//  WatchNutritionResult.swift
//  DialysisOneWatch Watch App
//
//  Lightweight model for nutrition data received from iPhone.
//

import Foundation

struct WatchNutritionResult: Equatable {
    let foodName: String
    let caloriesPer100g: Int
    let proteinPer100g: Double
    let potassiumPer100g: Int
    let sodiumPer100g: Int
    let confidence: String?   // "low", "moderate", "high"
    let source: String?       // "database", "ai"
    
    /// Create from WatchConnectivity payload dictionary
    static func from(_ payload: [String: Any]) -> WatchNutritionResult? {
        guard
            let foodName = payload["foodName"] as? String,
            let calories = payload["caloriesPer100g"] as? Int,
            let protein = payload["proteinPer100g"] as? Double,
            let potassium = payload["potassiumPer100g"] as? Int,
            let sodium = payload["sodiumPer100g"] as? Int
        else { return nil }
        
        return WatchNutritionResult(
            foodName: foodName,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            potassiumPer100g: potassium,
            sodiumPer100g: sodium,
            confidence: payload["confidence"] as? String,
            source: payload["source"] as? String
        )
    }
    
    /// Scale nutrients by quantity (grams)
    func scaled(by grams: Int) -> (calories: Int, protein: Double, potassium: Int, sodium: Int) {
        let scale = Double(grams) / 100.0
        return (
            calories: Int(Double(caloriesPer100g) * scale),
            protein: proteinPer100g * scale,
            potassium: Int(Double(potassiumPer100g) * scale),
            sodium: Int(Double(sodiumPer100g) * scale)
        )
    }
}
