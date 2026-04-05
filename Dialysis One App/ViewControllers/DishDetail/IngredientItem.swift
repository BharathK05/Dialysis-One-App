//
//  IngredientItem.swift
//  Dialysis One App
//
//  Model representing a single ingredient in a custom food creation flow.
//

import Foundation

struct IngredientItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let calories: Double
    let protein: Double
    let potassium: Double
    let sodium: Double
    var quantity: Double
    var unit: String
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Double,
        protein: Double,
        potassium: Double,
        sodium: Double,
        quantity: Double,
        unit: String
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.potassium = potassium
        self.sodium = sodium
        self.quantity = quantity
        self.unit = unit
    }
}
