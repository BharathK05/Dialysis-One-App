//
//  FoodSearchService.swift
//  Dialysis One App
//
//  Handles food search via Supabase RPC with ranking + local fallback
//  v2 - Fixed RPC params, added local table fallback, safe Codable decoding
//

import Supabase
import Foundation

// MARK: - Search Response Models

/// Matches the Supabase search_dishes RPC response
struct SearchResult: Codable {
    let dish_name: String
    let description: String?
    let tags: [String]?          // Optional — RPC may omit this field
    let confidence: Double
    let source: String?
    let popularity: Int?
    let calories: Int?
    
    // Convenience unwrap
    var safeTags: [String] { tags ?? [] }
    var safePopularity: Int { popularity ?? 0 }
    var safeSource: String { source ?? "unknown" }
}

/// Local dishes table fallback — minimal schema
private struct LocalDishRow: Codable {
    let dish_name: String
    let calories_per_100g: Int?
    let description: String?
}

// MARK: - Search Cache

final class SearchCache {
    static let shared = SearchCache()
    private init() {}
    
    private var cache: [String: [DishSuggestion]] = [:]
    private let lock = NSLock()
    
    func get(query: String) -> [DishSuggestion]? {
        lock.lock(); defer { lock.unlock() }
        return cache[query.lowercased()]
    }
    
    func set(_ results: [DishSuggestion], for query: String) {
        lock.lock(); defer { lock.unlock() }
        cache[query.lowercased()] = results
    }
    
    func clearAll() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAll()
    }
}

// MARK: - Food Search Service

final class FoodSearchService {
    
    static let shared = FoodSearchService()
    private init() {}
    
    // MARK: - Search Dishes (with fallback)
    
    func searchDishes(query: String, userId: String, limit: Int = 20) async throws -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        
        print("🔍 Query:", trimmed)
        
        // Try RPC first
        do {
            let results = try await callSearchRPC(query: trimmed, userId: userId, limit: limit)
            if !results.isEmpty {
                print("✅ [FoodSearchService] RPC returned \(results.count) results")
                return rankResults(results, query: trimmed)
            }
            print("⚠️ [FoodSearchService] RPC empty → using fallback")
        } catch {
            print("❌ [FoodSearchService] RPC failed: \(error)")
            print("⚠️ [FoodSearchService] RPC empty → using fallback")
        }
        
        // Fallback: direct table query
        do {
            let fallbackResults = try await searchLocalDishesTable(query: trimmed, limit: limit)
            return fallbackResults
        } catch {
            print("❌ [FoodSearchService] Fallback also failed: \(error)")
            return []
        }
    }
    
    // MARK: - RPC Call
    
    private func callSearchRPC(query: String, userId: String, limit: Int) async throws -> [SearchResult] {
        
        print("📡 API CALLED: search_dishes RPC")
        
        let params: [String: AnyJSON] = [
            "p_query": .string(query),
            "p_user_id": .string(userId),
            "p_limit": .integer(limit)
        ]
        
        let results: [SearchResult] = try await SupabaseService.shared.client
            .rpc("search_dishes", params: params)
            .execute()
            .value
        
        return results
    }
    
    // MARK: - Local Table Fallback
    
    private func searchLocalDishesTable(query: String, limit: Int) async throws -> [SearchResult] {
        print("🔎 [FoodSearchService] Querying local 'dishes' table for: '\(query)'")
        
        do {
            let rows: [LocalDishRow] = try await SupabaseService.shared.client
                .from("dishes")
                .select("dish_name, calories_per_100g, description")
                .ilike("dish_name", pattern: "%\(query)%")
                .limit(limit)
                .execute()
                .value
            
            print("✅ [FoodSearchService] Local table returned \(rows.count) rows")
            
            let converted = rows.map { row -> SearchResult in
                SearchResult(
                    dish_name: row.dish_name,
                    description: row.description,
                    tags: nil,
                    confidence: 0.8,
                    source: "local_db",
                    popularity: nil,
                    calories: row.calories_per_100g
                )
            }
            
            return rankResults(converted, query: query)
            
        } catch {
            print("❌ [FoodSearchService] Local table fallback also failed: \(error)")
            return []
        }
    }
    
    // MARK: - Local Ranking Logic
    
    /// 3-tier ranking: Exact → Prefix → Word-boundary → Contains
    func rankResults(_ results: [SearchResult], query: String) -> [SearchResult] {
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespaces)
        
        let scored = results.map { result -> (result: SearchResult, score: Int) in
            let name = result.dish_name.lowercased()
            var score = 0
            
            if name == normalizedQuery {
                score += 1000                                       // Tier 1: Exact
            } else if name.hasPrefix(normalizedQuery) {
                score += 500                                        // Tier 2: Prefix
            } else {
                let words = name.components(separatedBy: .whitespaces)
                if words.contains(where: { $0.hasPrefix(normalizedQuery) }) {
                    score += 300                                    // Tier 3: Word-boundary
                } else if name.contains(normalizedQuery) {
                    score += 200                                    // Tier 4: Contains
                }
            }
            
            score += Int((result.confidence) * 100)
            score += min(result.safePopularity, 50)
            
            return (result, score)
        }
        
        return scored
            .sorted { $0.score > $1.score }
            .map { $0.result }
    }
    
    // MARK: - Frequency Tracking
    
    func incrementDishFrequency(dishName: String, userId: String) async throws {
        struct FrequencyRecord: Codable {
            let user_id: String
            let dish_name: String
            let frequency_count: Int
            let last_used: String
        }
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        let existing: [FrequencyRecord] = try await SupabaseService.shared.client
            .from("user_dish_frequency")
            .select()
            .eq("user_id", value: userId)
            .eq("dish_name", value: dishName)
            .execute()
            .value
        
        if let existingRecord = existing.first {
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
        } else {
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
        }
    }
}

// MARK: - Helper Extensions

extension SearchResult {
    
    func toDishSuggestion() -> DishSuggestion {
        return DishSuggestion(
            name: dish_name,
            description: description ?? "",
            attributes: safeTags,
            matchScore: Int(confidence * 100),
            calories: calories
        )
    }
    
    var isHighConfidence: Bool { confidence >= 0.80 }
    var isLowConfidence: Bool { confidence < 0.50 }
}
