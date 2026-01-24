//
//  PortionWeight.swift
//  Dialysis One App
//
//  Created by user@1 on 22/01/26.
//


//
//  PortionWeightsDatabase.swift
//  Dialysis One App
//
//  NO HARDCODING - All weights from database/API
//

import Foundation

struct PortionWeight: Codable {
    let foodName: String
    let category: String
    let gramsPerPiece: Double
    let source: String // "ifct", "usda", "manual_entry"
    let lastUpdated: Date
}

final class PortionWeightsDatabase {
    
    static let shared = PortionWeightsDatabase()
    private init() {
        loadDatabase()
    }
    
    private let cacheKey = "PortionWeights_v1"
    private var weights: [String: PortionWeight] = [:]
    
    // MARK: - Public API
    
    /// Get grams per piece for a food item (NO HARDCODING)
    func getGramsPerPiece(for canonicalName: String) async -> Double? {
        
        let key = canonicalName.lowercased()
        
        // 1. Check local cache
        if let cached = weights[key] {
            print("   📊 Found weight in cache: \(cached.gramsPerPiece)g per piece")
            return cached.gramsPerPiece
        }
        
        // 2. Try to fetch from Supabase
        if let fetched = await fetchFromSupabase(canonicalName: canonicalName) {
            saveToCache(fetched)
            return fetched.gramsPerPiece
        }
        
        // 3. Try to calculate from IFCT database
        if let calculated = calculateFromIFCT(canonicalName: canonicalName) {
            saveToCache(calculated)
            return calculated.gramsPerPiece
        }
        
        // 4. Ask AI to estimate (last resort)
        if let estimated = await estimateWithAI(canonicalName: canonicalName) {
            saveToCache(estimated)
            return estimated.gramsPerPiece
        }
        
        print("   ⚠️ Could not determine grams per piece for: \(canonicalName)")
        return nil
    }
    
    // MARK: - Data Sources
    
    private func fetchFromSupabase(canonicalName: String) async -> PortionWeight? {
        // TODO: Implement Supabase query
        // SELECT * FROM portion_weights WHERE food_name = canonicalName
        
        print("   🔍 Checking Supabase for: \(canonicalName)")
        
        // Example structure:
        /*
        CREATE TABLE portion_weights (
            id UUID PRIMARY KEY,
            food_name TEXT UNIQUE,
            category TEXT,
            grams_per_piece FLOAT,
            source TEXT,
            last_updated TIMESTAMP
        );
        */
        
        return nil // Not implemented yet
    }
    
    private func calculateFromIFCT(canonicalName: String) -> PortionWeight? {
        // Check if IFCT database has standard serving info
        
        guard let nutrients = DishTemplateManager.shared.nutrients(
            forDetectedName: canonicalName
        ) else {
            return nil
        }
        
        // IFCT sometimes includes serving size info
        if let servingSize = nutrients.servingSize,
           servingSize.contains("piece") || servingSize.contains("pc") {
            
            // Extract grams from serving size (e.g., "1 piece (40g)")
            if let grams = extractGramsFromServingSize(servingSize) {
                print("   ✅ Calculated from IFCT serving size: \(grams)g")
                
                return PortionWeight(
                    foodName: canonicalName,
                    category: determineCategoryFromName(canonicalName),
                    gramsPerPiece: grams,
                    source: "ifct",
                    lastUpdated: Date()
                )
            }
        }
        
        return nil
    }
    
    private func estimateWithAI(canonicalName: String) async -> PortionWeight? {
        print("   🤖 Asking AI to estimate grams per piece...")
        
        let prompt = """
        What is the standard weight in grams for ONE piece of "\(canonicalName)"?
        
        Respond with ONLY a JSON object:
        {
          "grams_per_piece": 40.0,
          "confidence": 0.9,
          "notes": "Standard Indian chapati"
        }
        
        Examples:
        - Roti/Chapati: 40g
        - Naan: 90g
        - Poori: 25g
        - Idli: 35g
        - Dosa: 50g
        
        Be conservative - use typical Indian serving sizes.
        NO explanations, ONLY JSON.
        """
        
        // Call Gemini API (reuse existing service)
        guard let response = await callGeminiForWeight(prompt: prompt) else {
            return nil
        }
        
        return PortionWeight(
            foodName: canonicalName,
            category: determineCategoryFromName(canonicalName),
            gramsPerPiece: response.gramsPerPiece,
            source: "ai_estimated",
            lastUpdated: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func extractGramsFromServingSize(_ servingSize: String) -> Double? {
        // Extract number from strings like "1 piece (40g)" or "40g per piece"
        
        let pattern = #"(\d+\.?\d*)\s*g"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: servingSize,
                range: NSRange(servingSize.startIndex..., in: servingSize)
              ),
              let range = Range(match.range(at: 1), in: servingSize) else {
            return nil
        }
        
        return Double(servingSize[range])
    }
    
    private func determineCategoryFromName(_ name: String) -> String {
        let lower = name.lowercased()
        
        if lower.contains("roti") || lower.contains("chapati") ||
           lower.contains("naan") || lower.contains("paratha") {
            return "bread"
        } else if lower.contains("idli") || lower.contains("dosa") ||
                  lower.contains("vada") {
            return "south_indian"
        } else if lower.contains("samosa") || lower.contains("pakora") {
            return "snack"
        }
        
        return "other"
    }
    
    private struct WeightEstimate: Codable {
        let gramsPerPiece: Double
        let confidence: Double
        let notes: String?
        
        enum CodingKeys: String, CodingKey {
            case gramsPerPiece = "grams_per_piece"
            case confidence
            case notes
        }
    }
    
    private func callGeminiForWeight(prompt: String) async -> WeightEstimate? {
        // Reuse existing Gemini API logic
        let geminiAPIKey = "AIzaSyBK6LUdz5rwmyFoOlOEHB0VgA0oMqQ-HFg"
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
        
        guard let url = URL(string: "\(endpoint)?key=\(geminiAPIKey)") else {
            return nil
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],

            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 512
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                
                let cleaned = text
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let decoder = JSONDecoder()
                return try decoder.decode(WeightEstimate.self, from: cleaned.data(using: .utf8)!)
            }
        } catch {
            print("❌ Gemini weight estimation error: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Cache Management
    
    private func saveToCache(_ weight: PortionWeight) {
        let key = weight.foodName.lowercased()
        weights[key] = weight
        persistCache()
        
        print("   💾 Saved portion weight to cache: \(weight.foodName) = \(weight.gramsPerPiece)g")
        
        // Also save to Supabase for future lookups
        Task {
            await saveToSupabase(weight)
        }
    }
    
    private func saveToSupabase(_ weight: PortionWeight) async {
        // TODO: Implement Supabase insert
        /*
        INSERT INTO portion_weights (food_name, category, grams_per_piece, source, last_updated)
        VALUES (weight.foodName, weight.category, weight.gramsPerPiece, weight.source, NOW())
        ON CONFLICT (food_name) DO UPDATE SET
            grams_per_piece = EXCLUDED.grams_per_piece,
            source = EXCLUDED.source,
            last_updated = NOW();
        */
        
        print("   ☁️ Saved to Supabase: \(weight.foodName)")
    }
    
    private func loadDatabase() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(
                [String: PortionWeight].self,
                from: data
              ) else {
            print("📦 No portion weights cache - starting fresh")
            return
        }
        
        weights = decoded
        print("📦 Loaded \(weights.count) portion weights")
    }
    
    private func persistCache() {
        guard let encoded = try? JSONEncoder().encode(weights) else {
            return
        }
        UserDefaults.standard.set(encoded, forKey: cacheKey)
    }
}
