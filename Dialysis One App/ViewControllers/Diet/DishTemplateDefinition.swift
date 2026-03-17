//
//  DishTemplateDefinition.swift
//  Dialysis One App
//
//  Maps Gemini dish names → canonical keys → NutritionDatabase
//

import Foundation

/// Simple mapping from "what Gemini says" → "our DB key"
struct DishTemplateDefinition {
    let canonicalKey: String     // must match dish_name in SQLite (or a variant)
    let displayName: String      // nice name for UI (optional)
    let category: String?        // e.g., "curry", "bread", "rice dish"
}

final class DishTemplateManager {
    static let shared = DishTemplateManager()
    
    private let db = NutritionDatabase.shared
    
    /// Add all your archetypes / synonyms here over time.
    /// Keys are **normalized** names (lowercased, trimmed).
    private let templates: [String: DishTemplateDefinition] = [
        // --- Chole / Chana masala family ---
        "chole (chickpea curry)": DishTemplateDefinition(
            canonicalKey: "chana_masala",
            displayName: "Chole (Chickpea Curry)",
            category: "curry"
        ),
        "chole": DishTemplateDefinition(
            canonicalKey: "chana_masala",
            displayName: "Chole (Chickpea Curry)",
            category: "curry"
        ),
        "chana masala": DishTemplateDefinition(
            canonicalKey: "chana_masala",
            displayName: "Chana Masala",
            category: "curry"
        ),
        
        // --- Bhatura / Poori family ---
        "bhatura": DishTemplateDefinition(
            canonicalKey: "bhatura",
            displayName: "Bhatura",
            category: "bread"
        ),
        "poori": DishTemplateDefinition(
            canonicalKey: "bhatura",
            displayName: "Poori (Deep-fried bread)",
            category: "bread"
        ),
        "puri": DishTemplateDefinition(
            canonicalKey: "bhatura",
            displayName: "Poori (Deep-fried bread)",
            category: "bread"
        ),
        
        // --- Chole Bhature combo ---
        "chole bhature": DishTemplateDefinition(
            canonicalKey: "chana_masala",
            displayName: "Chole (Chickpea Curry)",
            category: "curry"
        ),
        "chole-bhature": DishTemplateDefinition(
            canonicalKey: "chana_masala",
            displayName: "Chole (Chickpea Curry)",
            category: "curry"
        ),
        "chole bhatura": DishTemplateDefinition(
            canonicalKey: "chana_masala",
            displayName: "Chole (Chickpea Curry)",
            category: "curry"
        ),
        
        // Add more dishes as needed:
        // "chicken biryani": DishTemplateDefinition(
        //     canonicalKey: "chicken_biryani",
        //     displayName: "Chicken Biryani",
        //     category: "rice dish"
        // ),
    ]
    
    private init() {}
    
    /// Normalize Gemini's name to a key we can compare.
    private func normalize(_ name: String) -> String {
        let lower = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // remove extra spaces
        let collapsed = lower.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return collapsed
    }
    
    /// Main API: from Gemini dish name → DishNutrients (if we can find / map it)
    func nutrients(forDetectedName detectedName: String) -> DishNutrients? {
        // 0️⃣ First: check user cache (AI/custom dishes)
        if let cached = UserDishCache.shared.nutrients(forDetectedName: detectedName) {
            print("✅ UserDishCache hit for \(detectedName)")
            return cached
        }
        
        // 1️⃣ Normalize the detected name
        let norm = normalize(detectedName)
        
        // 2️⃣ Check if we have a template mapping for this normalized name
        if let template = templates[norm] {
            print("✅ Template found for '\(detectedName)' → '\(template.canonicalKey)'")
            
            // Look up the canonical key in the nutrition database
            if let nutrients = db.lookupDish(byLabel: template.canonicalKey)  {
                return nutrients
            }
        }
        
        // 3️⃣ Try direct DB lookup with normalized name (fallback)
        if let fromDb = db.lookupDish(byLabel: norm) {
            print("✅ Direct DB hit for normalized name: \(norm)")
            return fromDb
        }
        
        // 4️⃣ Finally try the raw detected string (in case DB has nicer naming)
        if let fromRaw = db.lookupDish(byLabel: detectedName) {
            print("✅ Direct DB hit for raw name: \(detectedName)")
            return fromRaw
        }
        
        // ❌ Nothing found
        print("⚠️ No nutrition data found for: \(detectedName)")
        return nil
    }
}
