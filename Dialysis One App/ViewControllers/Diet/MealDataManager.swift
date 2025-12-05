import Foundation
import UIKit

// MARK: - Models

struct SavedMeal: Codable {
    let id: UUID
    let dishName: String
    let calories: Int
    let potassium: Int
    let sodium: Int
    let protein: Double
    let quantity: Int
    let mealType: MealType // breakfast, lunch, dinner
    let timestamp: Date
    let imageData: Data? // Store image as Data
    
    enum MealType: String, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
    }
}

// MARK: - Meal Data Manager

class MealDataManager {
    static let shared = MealDataManager()
    
    private let mealsKey = "saved_meals"
    
    private init() {}
    
    // MARK: - Get Current User ID
    
    private var uid: String {
        return FirebaseAuthManager.shared.getUserID() ?? "guest"
    }
    
    // MARK: - Save Meal
    
    func saveMeal(
        dishName: String,
        calories: Int,
        potassium: Int,
        sodium: Int,
        protein: Double,
        quantity: Int,
        mealType: SavedMeal.MealType,
        image: UIImage?
    ) {
        let imageData = image?.jpegData(compressionQuality: 0.7)
        
        let meal = SavedMeal(
            id: UUID(),
            dishName: dishName,
            calories: calories,
            potassium: potassium,
            sodium: sodium,
            protein: protein,
            quantity: quantity,
            mealType: mealType,
            timestamp: Date(),
            imageData: imageData
        )
        
        var meals = getAllMeals()
        meals.append(meal)
        
        saveMeals(meals)
        
        // Also update the nutrient totals in UserDataManager for persistence
        updateUserNutrientTotals()
        
        // Post notification to update UI
        NotificationCenter.default.post(name: .mealsDidUpdate, object: nil)
        
        print("✅ Meal saved successfully for user: \(uid)")
    }
    
    // MARK: - Get Meals
    
    func getAllMeals() -> [SavedMeal] {
        let key = UserDataManager.shared.key(mealsKey, uid: uid)
        
        guard let data = UserDefaults.standard.data(forKey: key),
              let meals = try? JSONDecoder().decode([SavedMeal].self, from: data) else {
            return []
        }
        return meals
    }
    
    func getMealsForToday() -> [SavedMeal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return getAllMeals().filter { meal in
            calendar.isDate(meal.timestamp, inSameDayAs: today)
        }
    }
    
    func getMeals(for mealType: SavedMeal.MealType, date: Date = Date()) -> [SavedMeal] {
        let calendar = Calendar.current
        return getMealsForToday().filter { meal in
            meal.mealType == mealType && calendar.isDate(meal.timestamp, inSameDayAs: date)
        }
    }
    
    // MARK: - Calculate Totals
    
    func getTodayTotals() -> (calories: Int, potassium: Int, sodium: Int, protein: Int) {
        let meals = getMealsForToday()
        
        let calories = meals.reduce(0) { $0 + $1.calories }
        let potassium = meals.reduce(0) { $0 + $1.potassium }
        let sodium = meals.reduce(0) { $0 + $1.sodium }
        let protein = Int(meals.reduce(0.0) { $0 + $1.protein })
        
        return (calories, potassium, sodium, protein)
    }
    
    // MARK: - Delete Meal
    
    func deleteMeal(id: UUID) {
        var meals = getAllMeals()
        meals.removeAll { $0.id == id }
        saveMeals(meals)
        
        // Update nutrient totals
        updateUserNutrientTotals()
        
        NotificationCenter.default.post(name: .mealsDidUpdate, object: nil)
        
        print("🗑️ Meal deleted for user: \(uid)")
    }
    
    // MARK: - Private Helpers
    
    private func saveMeals(_ meals: [SavedMeal]) {
        if let encoded = try? JSONEncoder().encode(meals) {
            let key = UserDataManager.shared.key(mealsKey, uid: uid)
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func updateUserNutrientTotals() {
        let totals = getTodayTotals()
        
        // Save to UserDataManager so it persists and syncs with Home screen
        UserDataManager.shared.save("potassiumConsumed", value: totals.potassium, uid: uid)
        UserDataManager.shared.save("sodiumConsumed", value: totals.sodium, uid: uid)
        UserDataManager.shared.save("proteinConsumed", value: totals.protein, uid: uid)
        
        print("📊 Nutrient totals updated:")
        print("   Potassium: \(totals.potassium) mg")
        print("   Sodium: \(totals.sodium) mg")
        print("   Protein: \(totals.protein) g")
    }
    
    func clearAllMeals() {
        let key = UserDataManager.shared.key(mealsKey, uid: uid)
        UserDefaults.standard.removeObject(forKey: key)
        
        // Reset nutrient totals
        UserDataManager.shared.save("potassiumConsumed", value: 0, uid: uid)
        UserDataManager.shared.save("sodiumConsumed", value: 0, uid: uid)
        UserDataManager.shared.save("proteinConsumed", value: 0, uid: uid)
        
        NotificationCenter.default.post(name: .mealsDidUpdate, object: nil)
        
        print("🧹 All meals cleared for user: \(uid)")
    }
    
    // MARK: - Get Meals by Date Range (for future features)
    
    func getMeals(from startDate: Date, to endDate: Date) -> [SavedMeal] {
        let calendar = Calendar.current
        return getAllMeals().filter { meal in
            calendar.isDate(meal.timestamp, inSameDayAs: startDate) ||
            (meal.timestamp >= startDate && meal.timestamp <= endDate)
        }
    }
    
    // MARK: - Statistics (for future features)
    
    func getAverageCaloriesForWeek() -> Int {
        let calendar = Calendar.current
        let today = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) else { return 0 }
        
        let meals = getMeals(from: weekAgo, to: today)
        let totalCalories = meals.reduce(0) { $0 + $1.calories }
        
        return meals.isEmpty ? 0 : totalCalories / 7
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let mealsDidUpdate = Notification.Name("mealsDidUpdate")
}
