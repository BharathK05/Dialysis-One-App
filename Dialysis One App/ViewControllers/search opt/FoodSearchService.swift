//
//  FoodSearchService.swift
//  Dialysis One App
//
//  Handles food search via Supabase RPC
//
import Supabase
import Foundation

// MARK: - Search Response Models

struct SearchResult: Codable {
    let dish_name: String
    let description: String?
    let tags: [String]
    let confidence: Double
    let source: String
    let popularity: Int
}

// MARK: - Food Search Service

final class FoodSearchService {
    
    static let shared = FoodSearchService()
    private init() {}
    
    // MARK: - Search Dishes
    
    func searchDishes(query: String, userId: String, limit: Int = 10) async throws -> [SearchResult] {
        
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        
        // Call Supabase RPC function
        let results: [SearchResult] = try await SupabaseService.shared.client
            .rpc("search_dishes", params: [
                "p_query": query,
                "p_user_id": userId,
                "p_limit": String(limit) 
            ])
            .execute()
            .value
        
        print("🔍 Search '\(query)' returned \(results.count) results")
        
        return results
    }
    
    // MARK: - Update User Frequency
    
    func incrementDishFrequency(dishName: String, userId: String) async throws {
        
        // First, try to fetch existing record
        struct FrequencyRecord: Codable {
            let user_id: String
            let dish_name: String
            let frequency_count: Int
            let last_used: String
        }
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        // Try to get existing record
        let existing: [FrequencyRecord] = try await SupabaseService.shared.client
            .from("user_dish_frequency")
            .select()
            .eq("user_id", value: userId)
            .eq("dish_name", value: dishName)
            .execute()
            .value
        
        if let existingRecord = existing.first {
            // Update existing record
            let updated = FrequencyRecord(
                user_id: userId,
                dish_name: dishName,
                frequency_count: existingRecord.frequency_count + 1,
                last_used: now
            )
            
            try await SupabaseService.shared.client
                .from("user_dish_frequency")
                .update(updated)
                .eq("user_id", value: userId)
                .eq("dish_name", value: dishName)
                .execute()
            
            print("✅ Updated frequency for: \(dishName) (count: \(updated.frequency_count))")
        } else {
            // Insert new record
            let newRecord = FrequencyRecord(
                user_id: userId,
                dish_name: dishName,
                frequency_count: 1,
                last_used: now
            )
            
            try await SupabaseService.shared.client
                .from("user_dish_frequency")
                .insert(newRecord)
                .execute()
            
            print("✅ Created frequency tracking for: \(dishName)")
        }
    }
}

// MARK: - Helper Extensions

extension SearchResult {
    
    func toDishSuggestion() -> DishSuggestion {
        return DishSuggestion(
            name: dish_name,
            description: description ?? "",
            attributes: tags,
            matchScore: Int(confidence * 100)
        )
    }
    
    var isHighConfidence: Bool {
        return confidence >= 0.80
    }
    
    var isLowConfidence: Bool {
        return confidence < 0.50
    }
}
