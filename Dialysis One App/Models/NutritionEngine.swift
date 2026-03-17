////
////  NutritionSource.swift
////  Dialysis One App
////
////  Created by user@1 on 20/01/26.
////
//
//
////
////  NutritionEngine.swift
////  Dialysis One App
////
////  Central, authoritative nutrition computation engine.
////  This is the ONLY place that decides calories, protein,
////  potassium, and sodium values.
////
////  LLM is used strictly as a fallback with LOW confidence.
////
//
//import Foundation
//
//// MARK: - Nutrition Source
//
//enum NutritionSource: String, Codable {
//    case reference = "REFERENCE"
//    case aiEstimated = "AI_ESTIMATED"
//}
//
//// MARK: - Confidence Level
//
//enum NutritionConfidence: String, Codable {
//    case high
//    case medium
//    case low
//}
//
//// MARK: - Food Context Enums
//
//enum FoodSourceType: String, Codable {
//    case homeCooked
//    case restaurant
//    case packaged
//}
//
//enum SaltLevel: String, Codable {
//    case low
//    case normal
//    case high
//}
//
//// MARK: - Nutrition Context (INPUT)
//
//struct NutritionContext {
//    let dishName: String
//    let portionInGrams: Double
//    let foodSource: FoodSourceType
//    let saltLevel: SaltLevel
//}
//
//// MARK: - Final Computed Output (OUTPUT)
//
//struct ComputedNutrition {
//    let dishName: String
//
//    let calories: Double
//    let protein: Double
//    let potassium: Double
//    let sodium: Double
//
//    let source: NutritionSource
//    let confidence: NutritionConfidence
//
//    let warnings: [String]
//}
//
//// MARK: - Safety Thresholds (Dialysis-aware)
//
//private enum NutritionSafety {
//    static let maxPotassiumPerMeal: Double = 800   // mg
//    static let maxSodiumPerMeal: Double = 700      // mg
//}
//
//// MARK: - Nutrition Engine
//
//final class NutritionEngine {
//
//    static let shared = NutritionEngine()
//    private init() {}
//
//    // MARK: - Public API
//
//    /// Main entry point for computing nutrition.
//    /// This method ALWAYS returns a result with confidence & warnings.
//    func computeNutrition(
//        context: NutritionContext
//    ) async -> ComputedNutrition {
//
//        // 1️⃣ Reference-first (HIGH confidence)
//        if let reference = NutritionDatabase.lookup(dishName: context.dishName) {
//            return computeFromReference(
//                reference: reference,
//                context: context
//            )
//        }
//
//        // 2️⃣ Fallback to LLM (LOW confidence)
//        if let llmEstimate = await LLMNutritionService.shared.estimateNutrients(
//            forDishName: context.dishName,
//            quantityHint: "\(context.portionInGrams)g"
//        ) {
//            return computeFromLLM(
//                llmEstimate,
//                context: context
//            )
//        }
//
//        // 3️⃣ Absolute safe fallback
//        return ComputedNutrition(
//            dishName: context.dishName,
//            calories: 0,
//            protein: 0,
//            potassium: 0,
//            sodium: 0,
//            source: .aiEstimated,
//            confidence: .low,
//            warnings: ["Nutrition data unavailable"]
//        )
//    }
//}
//
//// MARK: - Reference-based Computation (HIGH confidence)
//
//private extension NutritionEngine {
//
//    func computeFromReference(
//        reference: DishNutrients,
//        context: NutritionContext
//    ) -> ComputedNutrition {
//
//        let factor = context.portionInGrams / 100.0
//
//        var calories = reference.calories * factor
//        var protein = reference.protein * factor
//        var potassium = reference.potassium * factor
//        var sodium = reference.sodium * factor
//
//        // 🔧 Context modifiers
//        switch context.foodSource {
//        case .restaurant:
//            sodium *= 1.4
//        case .packaged:
//            sodium *= 1.2
//        case .homeCooked:
//            break
//        }
//
//        switch context.saltLevel {
//        case .high:
//            sodium *= 1.3
//        case .low:
//            sodium *= 0.85
//        case .normal:
//            break
//        }
//
//        let warnings = generateWarnings(
//            potassium: potassium,
//            sodium: sodium
//        )
//
//        return ComputedNutrition(
//            dishName: context.dishName,
//            calories: round(calories),
//            protein: round(protein),
//            potassium: round(potassium),
//            sodium: round(sodium),
//            source: .reference,
//            confidence: .high,
//            warnings: warnings
//        )
//    }
//}
//
//// MARK: - LLM-based Computation (LOW confidence, guarded)
//
//private extension NutritionEngine {
//
//    func computeFromLLM(
//        _ llm: DishNutrients,
//        context: NutritionContext
//    ) -> ComputedNutrition {
//
//        let factor = context.portionInGrams / 100.0
//
//        let calories = llm.calories * factor
//        let protein = llm.protein * factor
//        let potassium = llm.potassium * factor
//        let sodium = llm.sodium * factor
//
//        let warnings = generateWarnings(
//            potassium: potassium,
//            sodium: sodium
//        ) + ["Estimated using AI"]
//
//        return ComputedNutrition(
//            dishName: context.dishName,
//            calories: round(calories),
//            protein: round(protein),
//            potassium: round(potassium),
//            sodium: round(sodium),
//            source: .aiEstimated,
//            confidence: .low,
//            warnings: warnings
//        )
//    }
//}
//
//// MARK: - Safety & Utilities
//
//private extension NutritionEngine {
//
//    func generateWarnings(
//        potassium: Double,
//        sodium: Double
//    ) -> [String] {
//
//        var warnings: [String] = []
//
//        if potassium > NutritionSafety.maxPotassiumPerMeal {
//            warnings.append("High potassium for a single meal")
//        }
//
//        if sodium > NutritionSafety.maxSodiumPerMeal {
//            warnings.append("High sodium for a single meal")
//        }
//
//        return warnings
//    }
//
//    /// Round to 1 decimal place for UI consistency
//    func round(_ value: Double) -> Double {
//        (value * 10).rounded() / 10
//    }
//}
