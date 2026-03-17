//
//  CachedNutrition.swift
//  Dialysis One App
//
//  Created by user@1 on 22/01/26.
//


//
//  NutritionCacheManager.swift
//  Dialysis One App
//
//  Handles DB lookup → Calculate → Save flow
//

import Foundation

struct CachedNutrition: Codable {
    let canonicalName: String
    let portionType: PortionType
    let nutrientsPer100g: DishNutrients
    let timestamp: Date
    let source: String // "ifct_db", "ai_calculated"
}

final class NutritionCacheManager {
    
    static let shared = NutritionCacheManager()
    private init() {
        loadCache()
    }
    
    private let cacheKey = "NutritionCache_v1"
    private var cache: [String: CachedNutrition] = [:]
    
    // MARK: - Public API
    
    /// Main flow: Try DB → Calculate if needed → Save → Return
    func getNutrition(
        for classifiedFood: ClassifiedFood
    ) async -> DishNutrients? {
        
        let canonicalName = classifiedFood.canonical_food_name
        
        print("\n🔍 Getting nutrition for: \(canonicalName)")
        
        // Step 1: Check cache first
        if let cached = cache[canonicalName] {
            print("   ✅ Found in cache (\(cached.source))")
            return cached.nutrientsPer100g
        }
        
        // Step 2: Check IFCT DB
        if let dbNutrients = DishTemplateManager.shared.nutrients(
            forDetectedName: canonicalName
        ) {
            print("   ✅ Found in IFCT DB")
            
            // Save to cache
            let cached = CachedNutrition(
                canonicalName: canonicalName,
                portionType: classifiedFood.portion_type,
                nutrientsPer100g: dbNutrients,
                timestamp: Date(),
                source: "ifct_db"
            )
            saveToCache(cached)
            
            return dbNutrients
        }
        
        // Step 3: Not found - Calculate using AI
        print("   ⚠️ Not in DB - calculating with AI...")
        
        guard let calculated = await LLMNutritionService.shared.estimateNutrients(
            forDishName: canonicalName,
            categoryHint: classifiedFood.food_category.rawValue,
            quantityHint: nil
        ) else {
            print("   ❌ AI calculation failed")
            return nil
        }
        
        print("   ✅ AI calculation successful")
        
        // Step 4: Save calculated nutrition to cache
        let cached = CachedNutrition(
            canonicalName: canonicalName,
            portionType: classifiedFood.portion_type,
            nutrientsPer100g: calculated,
            timestamp: Date(),
            source: "ai_calculated"
        )
        saveToCache(cached)
        
        return calculated
    }
    
    /// Get source info for display
    func getSource(for canonicalName: String) -> String? {
        return cache[canonicalName]?.source
    }
    
    // MARK: - Cache Management
    
    private func saveToCache(_ nutrition: CachedNutrition) {
        cache[nutrition.canonicalName] = nutrition
        persistCache()
        
        print("   💾 Saved to cache: \(nutrition.canonicalName)")
    }
    
    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(
                [String: CachedNutrition].self,
                from: data
              ) else {
            print("📦 No nutrition cache found - starting fresh")
            return
        }
        
        cache = decoded
        print("📦 Loaded \(cache.count) cached nutrition entries")
    }
    
    private func persistCache() {
        guard let encoded = try? JSONEncoder().encode(cache) else {
            print("❌ Failed to encode nutrition cache")
            return
        }
        
        UserDefaults.standard.set(encoded, forKey: cacheKey)
    }
    
    /// Clear cache (for testing)
    func clearCache() {
        cache.removeAll()
        UserDefaults.standard.removeObject(forKey: cacheKey)
        print("🗑️ Nutrition cache cleared")
    }
}