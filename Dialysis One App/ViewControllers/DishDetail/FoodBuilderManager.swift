//
//  FoodBuilderManager.swift
//  Dialysis One App
//
//  Central state manager for the custom food creation flow.
//  Holds the ingredient list and food name, independent of any ViewController.
//

import Foundation

protocol FoodBuilderManagerDelegate: AnyObject {
    func foodBuilderDidUpdateIngredients()
}

final class FoodBuilderManager {
    
    // MARK: - Shared Instance
    
    static let shared = FoodBuilderManager()
    private init() {}
    
    // MARK: - Delegate
    
    weak var delegate: FoodBuilderManagerDelegate?
    
    // MARK: - State
    
    private(set) var foodName: String = ""
    private(set) var ingredients: [IngredientItem] = []
    
    // MARK: - Computed Properties
    
    var totalCalories: Double {
        ingredients.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        ingredients.reduce(0) { $0 + $1.protein }
    }
    
    var totalPotassium: Double {
        ingredients.reduce(0) { $0 + $1.potassium }
    }
    
    var totalSodium: Double {
        ingredients.reduce(0) { $0 + $1.sodium }
    }
    
    var ingredientCount: Int {
        ingredients.count
    }
    
    var isEmpty: Bool {
        ingredients.isEmpty
    }
    
    // MARK: - Mutating Methods
    
    func setFoodName(_ name: String) {
        foodName = name
    }
    
    func addIngredient(_ ingredient: IngredientItem) {
        ingredients.append(ingredient)
        delegate?.foodBuilderDidUpdateIngredients()
        print("✅ FoodBuilder: Added ingredient '\(ingredient.name)' (\(Int(ingredient.calories)) kcal). Total: \(ingredients.count)")
    }
    
    func updateIngredient(at index: Int, with updated: IngredientItem) {
        guard index >= 0 && index < ingredients.count else { return }
        ingredients[index] = updated
        delegate?.foodBuilderDidUpdateIngredients()
        print("✅ FoodBuilder: Updated ingredient at index \(index)")
    }
    
    func removeIngredient(at index: Int) {
        guard index >= 0 && index < ingredients.count else { return }
        let removed = ingredients.remove(at: index)
        delegate?.foodBuilderDidUpdateIngredients()
        print("🗑️ FoodBuilder: Removed ingredient '\(removed.name)'. Remaining: \(ingredients.count)")
    }
    
    func removeIngredient(withId id: UUID) {
        ingredients.removeAll { $0.id == id }
        delegate?.foodBuilderDidUpdateIngredients()
    }
    
    /// Reset all state for a new food creation session
    func reset() {
        foodName = ""
        ingredients = []
        delegate = nil
        print("🔄 FoodBuilder: Reset for new session")
    }
    
    // MARK: - Build Final Meal
    
    /// Builds a composite meal from all current ingredients
    func buildCompositeMeal() -> (dishName: String, calories: Int, protein: Double, potassium: Int, sodium: Int)? {
        guard !foodName.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("⚠️ FoodBuilder: Cannot build - no food name")
            return nil
        }
        guard !ingredients.isEmpty else {
            print("⚠️ FoodBuilder: Cannot build - no ingredients")
            return nil
        }
        
        return (
            dishName: foodName,
            calories: Int(totalCalories),
            protein: totalProtein,
            potassium: Int(totalPotassium),
            sodium: Int(totalSodium)
        )
    }
}
