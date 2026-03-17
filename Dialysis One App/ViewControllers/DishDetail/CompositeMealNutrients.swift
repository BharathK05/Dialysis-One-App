//
//  CompositeMealNutrients.swift
//  Dialysis One App
//
//  Created by user@1 on 30/12/25.
//


//
//  CompositeMealNutrientCalculator.swift
//  Dialysis One App
//
//  Calculate total nutrients for composite meals (sum of all items)
//

import Foundation

struct CompositeMealNutrients {
    let totalNutrients: DishNutrients
    let itemBreakdown: [(food: DetectedFood, nutrients: DishNutrients)]
    let successfulCount: Int
    let failedItems: [String]
}

final class CompositeMealNutrientCalculator {
    
    static let shared = CompositeMealNutrientCalculator()
    private init() {}
    
    /// Calculate total nutrients for a composite meal by summing all detected items
    func calculateCompositeNutrients(
        mealName: String,
        detectedFoods: [DetectedFood]
    ) async -> CompositeMealNutrients? {
        
        print("\n🧮 ========== CALCULATING COMPOSITE MEAL NUTRIENTS ==========")
        print("📋 Meal: \(mealName)")
        print("📋 Total items to calculate: \(detectedFoods.count)")
        
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalPotassium: Double = 0
        var totalSodium: Double = 0
        
        var itemBreakdown: [(food: DetectedFood, nutrients: DishNutrients)] = []
        var failedItems: [String] = []
        var successfulCount = 0
        
        // Process each detected food item
        for (index, food) in detectedFoods.enumerated() {
            print("\n📍 Item \(index + 1)/\(detectedFoods.count): \(food.name)")
            
            // Try to get nutrients from database first
            if let dbNutrients = DishTemplateManager.shared.nutrients(forDetectedName: food.name) {
                print("   ✅ Found in database")
                
                // Parse quantity to get actual grams
                let estimatedGrams = extractGramsFromQuantity(food.quantity, dishName: food.name)
                print("   📏 Estimated grams: \(estimatedGrams)g")
                
                // Scale nutrients based on actual serving size
                let multiplier = estimatedGrams / 100.0
                let scaledNutrients = scaleNutrients(dbNutrients, by: multiplier)
                
                totalCalories += scaledNutrients.calories
                totalProtein += scaledNutrients.protein
                totalPotassium += scaledNutrients.potassium
                totalSodium += scaledNutrients.sodium
                
                itemBreakdown.append((food, scaledNutrients))
                successfulCount += 1
                
                print("   🔢 Scaled calories: \(Int(scaledNutrients.calories)) kcal")
                
            } else {
                // Fallback to LLM estimation
                print("   ⚠️ Not in database, using LLM estimate...")
                
                if let llmNutrients = await LLMNutritionService.shared.estimateNutrients(
                    forDishName: food.name,
                    categoryHint: food.type,
                    quantityHint: food.quantity
                ) {
                    print("   ✅ LLM estimate successful")
                    
                    let estimatedGrams = extractGramsFromQuantity(food.quantity, dishName: food.name)
                    let multiplier = estimatedGrams / 100.0
                    let scaledNutrients = scaleNutrients(llmNutrients, by: multiplier)
                    
                    totalCalories += scaledNutrients.calories
                    totalProtein += scaledNutrients.protein
                    totalPotassium += scaledNutrients.potassium
                    totalSodium += scaledNutrients.sodium
                    
                    itemBreakdown.append((food, scaledNutrients))
                    successfulCount += 1
                    
                    print("   🔢 Scaled calories: \(Int(scaledNutrients.calories)) kcal")
                    
                } else {
                    print("   ❌ Failed to get nutrients")
                    failedItems.append(food.name)
                }
            }
        }
        
        print("\n✅ CALCULATION COMPLETE")
        print("   Successful items: \(successfulCount)/\(detectedFoods.count)")
        print("   Failed items: \(failedItems.count)")
        print("   📊 TOTAL CALORIES: \(Int(totalCalories)) kcal")
        print("   📊 TOTAL PROTEIN: \(String(format: "%.1f", totalProtein))g")
        print("   📊 TOTAL POTASSIUM: \(Int(totalPotassium))mg")
        print("   📊 TOTAL SODIUM: \(Int(totalSodium))mg")
        print("============================================\n")
        
        guard successfulCount > 0 else {
            print("⚠️ No items could be calculated")
            return nil
        }
        
        // Create composite nutrients object
        let compositeNutrients = DishNutrients(
            dishName: mealName,
            calories: totalCalories,
            protein: totalProtein,
            potassium: totalPotassium,
            sodium: totalSodium,
            ckdTag: nil,
            confidence: nil,
            servingSize: "\(detectedFoods.count) items",
            isCompositeFinal: true
        )
        
        return CompositeMealNutrients(
            totalNutrients: compositeNutrients,
            itemBreakdown: itemBreakdown,
            successfulCount: successfulCount,
            failedItems: failedItems
        )
    }
    
    // MARK: - Private Helpers
    
    /// Extract estimated grams from quantity hint
    private func extractGramsFromQuantity(_ quantity: String?, dishName: String) -> Double {
        guard let quantity = quantity?.lowercased() else {
            return estimateDefaultGrams(for: dishName)
        }
        
        // Parse quantity hints
        if quantity.contains("serving") || quantity.contains("bowl") {
            return 150.0
        } else if quantity.contains("plate") || quantity.contains("thali") {
            return 250.0
        } else if quantity.contains("cup") || quantity.contains("katori") {
            return 100.0
        } else if quantity.contains("piece") {
            return 50.0
        } else if quantity.contains("small") {
            return 75.0
        } else if quantity.contains("large") {
            return 200.0
        } else {
            // Try to extract numeric value
            let components = quantity.components(separatedBy: CharacterSet.decimalDigits.inverted)
            if let first = components.first(where: { !$0.isEmpty }),
               let value = Double(first) {
                // If we found a number, assume it's a multiplier
                return value * 100.0
            }
            return estimateDefaultGrams(for: dishName)
        }
    }
    
    /// Estimate default grams based on dish type
    private func estimateDefaultGrams(for dishName: String) -> Double {
        let name = dishName.lowercased()
        
        if name.contains("rice") {
            return 150.0
        } else if name.contains("curry") || name.contains("dal") || name.contains("sambar") {
            return 100.0
        } else if name.contains("roti") || name.contains("chapati") || name.contains("naan") {
            return 40.0
        } else if name.contains("papad") {
            return 10.0
        } else if name.contains("sweet") || name.contains("jalebi") || name.contains("dessert") {
            return 50.0
        } else if name.contains("raita") || name.contains("chutney") {
            return 50.0
        } else {
            // Default serving
            return 100.0
        }
    }
    
    /// Scale nutrients by multiplier
    private func scaleNutrients(_ nutrients: DishNutrients, by multiplier: Double) -> DishNutrients {
        return DishNutrients(
            dishName: nutrients.dishName,
            calories: nutrients.calories * multiplier,
            protein: nutrients.protein * multiplier,
            potassium: nutrients.potassium * multiplier,
            sodium: nutrients.sodium * multiplier,
            ckdTag: nutrients.ckdTag,
            confidence: nutrients.confidence,
            servingSize: nutrients.servingSize,
            isCompositeFinal: true

        )
    }
}
