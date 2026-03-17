//
//  SupabaseService.swift
//  Dialysis One App
//
//  Created by user@1 on 08/12/25.
//


//
//  SupabaseService.swift
//  Dialysis One App
//
//  Central service for all Supabase operations
//

import Foundation
import Supabase

final class SupabaseService {
    
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        // Load credentials from Secrets.plist (or you can use Secrets.swift)
        guard
            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let supabaseURLString = dict["SUPABASE_URL"] as? String,
            let supabaseKeyString = dict["SUPABASE_KEY"] as? String,
            let url = URL(string: supabaseURLString)
        else {
            fatalError("❌ Missing Supabase credentials in Secrets.plist")
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKeyString
        )
        
        print("✅ SupabaseService initialized")
    }
    
    // MARK: - Meal Logging
    
    /// Log a meal to Supabase (async, non-blocking)
    func logMeal(_ record: MealRecord) async throws {
        print("\n📤 Syncing meal to Supabase: \(record.dish_name)")
        
        do {
            let response = try await client
                .from("meals")
                .insert(record)
                .execute()
            
            print("✅ Meal synced successfully to Supabase")
            print("   Response: \(response.status)")
            
        } catch {
            print("❌ Failed to sync meal to Supabase: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Log a meal in the background (fire-and-forget)
    func logMealInBackground(_ record: MealRecord) {
        Task {
            do {
                try await logMeal(record)
            } catch {
                // Silently fail - local data is already saved
                print("⚠️ Background sync failed, but local data is safe")
            }
        }
    }
    
    // MARK: - Fetch Meals
    
    /// Fetch all meals for current user
    func fetchMeals(userId: String) async throws -> [MealRecord] {
        print("\n📥 Fetching meals from Supabase for user: \(userId)")
        
        let response = try await client
            .from("meals")
            .select()
            .eq("user_id", value: userId)
            .order("timestamp", ascending: false)
            .execute()
        
        let meals = try JSONDecoder().decode([MealRecord].self, from: response.data)
        print("✅ Fetched \(meals.count) meals from Supabase")
        
        return meals
    }
    
    /// Fetch meals for a specific date range
    func fetchMeals(
        userId: String,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [MealRecord] {
        print("\n📥 Fetching meals from \(startDate) to \(endDate)")
        
        let response = try await client
            .from("meals")
            .select()
            .eq("user_id", value: userId)
            .gte("timestamp", value: startDate.ISO8601Format())
            .lte("timestamp", value: endDate.ISO8601Format())
            .order("timestamp", ascending: false)
            .execute()
        
        let meals = try JSONDecoder().decode([MealRecord].self, from: response.data)
        print("✅ Fetched \(meals.count) meals for date range")
        
        return meals
    }
    
    // MARK: - Delete Meal
    
    /// Delete a meal from Supabase by local meal ID
    /// Note: This requires storing the Supabase UUID in SavedMeal later
    func deleteMeal(supabaseId: UUID) async throws {
        print("\n🗑️ Deleting meal from Supabase: \(supabaseId)")
        
        try await client
            .from("meals")
            .delete()
            .eq("id", value: supabaseId.uuidString)
            .execute()
        
        print("✅ Meal deleted from Supabase")
    }
    
    // MARK: - Health Check
    
    /// Test Supabase connection
    // MARK: - Health Check

    /// Test Supabase connection
    func testConnection() async -> Bool {
        do {
            let response = try await client
                .from("meals")
                .select()  // ✅ Remove "columns:" parameter
                .limit(1)
                .execute()
            
            print("✅ Supabase connection successful")
            return true
            
        } catch {
            print("❌ Supabase connection failed: \(error.localizedDescription)")
            return false
        }
    }
    func logDishCorrection(userId: String, detected: String, confirmed: String) async throws {
        let correction: [String: Any] = [
            "user_id": userId,
            "detected_dish": detected,
            "confirmed_dish": confirmed,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // TODO: Add to your Supabase table for learning
        print("📝 Dish correction logged: \(detected) → \(confirmed)")
    }
}
