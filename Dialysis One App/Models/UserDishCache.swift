//
//  UserDishCache.swift
//  Dialysis One App
//
//  Created by user@1 on 08/12/25.
//


//
//  UserDishCache.swift
//  Dialysis One App
//
//  Stores nutrients for dishes that were estimated by AI (or custom).
//  So next time the same dish appears, we can skip the LLM call.
//

import Foundation

final class UserDishCache {
    
    static let shared = UserDishCache()
    
    private let storageKey = "UserDishCache_v1"
    
    /// key = normalized dish name, value = nutrients (per 100g)
    private var cache: [String: DishNutrients] = [:]
    
    private init() {
        loadFromDisk()
    }
    
    // MARK: - Public API
    
    func nutrients(forDetectedName name: String) -> DishNutrients? {
        let key = normalize(name)
        return cache[key]
    }
    
    func saveNutrients(_ nutrients: DishNutrients, forDetectedName name: String) {
        let key = normalize(name)
        cache[key] = nutrients
        persistToDisk()
    }
    
    // MARK: - Normalization
    
    private func normalize(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
    }
    
    // MARK: - Persistence
    
    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([String: DishNutrients].self, from: data)
            cache = decoded
        } catch {
            print("⚠️ UserDishCache: failed to decode cache – \(error.localizedDescription)")
        }
    }
    
    private func persistToDisk() {
        do {
            let data = try JSONEncoder().encode(cache)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("⚠️ UserDishCache: failed to encode cache – \(error.localizedDescription)")
        }
    }
}