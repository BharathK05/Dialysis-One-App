//
//  MealRecord.swift
//  Dialysis One App
//
//  Created by user@1 on 08/12/25.
//


//
//  MealRecord.swift
//  Dialysis One App
//
//  Model for syncing meals to Supabase
//

import Foundation

/// Lightweight model that mirrors the Supabase `meals` table
struct MealRecord: Codable {
    let id: UUID?
    let user_id: String
    let dish_name: String
    let calories: Int
    let potassium: Int
    let sodium: Int
    let protein: Double
    let quantity: Int
    let meal_type: String
    let source: String?
    let timestamp: Date
    let image_url: String?
    
    // Optional future fields
    let ckd_stage_at_time: String?
    let weight_at_time: Double?
    
    /// Create from SavedMeal + additional context
    init(
        from meal: SavedMeal,
        userId: String,
        source: String?,
        ckdStage: String? = nil,
        weight: Double? = nil
    ) {
        self.id = nil // Let Supabase generate
        self.user_id = userId
        self.dish_name = meal.dishName
        self.calories = meal.calories
        self.potassium = meal.potassium
        self.sodium = meal.sodium
        self.protein = meal.protein
        self.quantity = meal.quantity
        self.meal_type = meal.mealType.rawValue.lowercased()
        self.source = source
        self.timestamp = meal.timestamp
        self.image_url = nil // TODO: Upload to Supabase Storage later
        self.ckd_stage_at_time = ckdStage
        self.weight_at_time = weight
    }
    
    /// Custom coding keys to match snake_case DB columns
    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case dish_name
        case calories
        case potassium
        case sodium
        case protein
        case quantity
        case meal_type
        case source
        case timestamp
        case image_url
        case ckd_stage_at_time
        case weight_at_time
    }
}