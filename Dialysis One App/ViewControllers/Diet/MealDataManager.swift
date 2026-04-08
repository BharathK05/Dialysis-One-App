//
//  MealDataManager.swift
//  Dialysis One App
//
//  Thin proxy layer — public API is UNCHANGED.
//  All persistence now delegates to ActivityLogManager (SwiftData).
//  DO NOT reintroduce UserDefaults reads/writes for meal data here.
//

import Foundation
import UIKit

// MARK: - SavedMeal (backward-compatibility value type)

struct SavedMeal: Codable {
    let id: UUID
    let dishName: String
    let calories: Int
    let potassium: Int
    let sodium: Int
    let protein: Double
    let quantity: Int
    let mealType: MealType
    let timestamp: Date
    let imageData: Data?

    enum MealType: String, Codable {
        case breakfast = "Breakfast"
        case lunch     = "Lunch"
        case dinner    = "Dinner"
    }
}

// MARK: - Conversion helper

private extension FoodLog {
    func toSavedMeal() -> SavedMeal {
        SavedMeal(
            id:        id,
            dishName:  dishName,
            calories:  calories,
            potassium: potassium,
            sodium:    sodium,
            protein:   protein,
            quantity:  quantity,
            mealType:  SavedMeal.MealType(rawValue: mealType) ?? .breakfast,
            timestamp: timestamp,
            imageData: imageData
        )
    }
}

// MARK: - MealDataManager

class MealDataManager {
    static let shared = MealDataManager()
    private init() {}

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

        ActivityLogManager.shared.saveFoodLog(
            dishName:  dishName,
            mealType:  mealType.rawValue,
            calories:  calories,
            protein:   protein,
            potassium: potassium,
            sodium:    sodium,
            quantity:  quantity,
            imageData: imageData
        )

        NotificationCenter.default.post(name: .mealsDidUpdate, object: nil)
        print("✅ Meal saved via SwiftData: \(dishName)")
    }

    // MARK: - Get Meals

    func getAllMeals() -> [SavedMeal] {
        ActivityLogManager.shared.allFoodLogs().map { $0.toSavedMeal() }
    }

    func getMealsForToday() -> [SavedMeal] {
        ActivityLogManager.shared.foodLogs(for: Date()).map { $0.toSavedMeal() }
    }

    func getMeals(for mealType: SavedMeal.MealType, date: Date = Date()) -> [SavedMeal] {
        ActivityLogManager.shared.foodLogs(for: date)
            .filter { $0.mealType == mealType.rawValue }
            .map    { $0.toSavedMeal() }
    }

    // MARK: - Totals

    func getTodayTotals() -> (calories: Int, potassium: Int, sodium: Int, protein: Int) {
        ActivityLogManager.shared.todayNutrientTotals()
    }

    // MARK: - Delete

    func deleteMeal(id: UUID) {
        ActivityLogManager.shared.deleteFoodLog(id: id)
        NotificationCenter.default.post(name: .mealsDidUpdate, object: nil)
        print("🗑️ Meal deleted from SwiftData")
    }

    // MARK: - Clear

    func clearAllMeals() {
        ActivityLogManager.shared.clearAllFoodLogs()
        NotificationCenter.default.post(name: .mealsDidUpdate, object: nil)
        print("🧹 All meals cleared from SwiftData")
    }

    // MARK: - Date Range

    func getMeals(from startDate: Date, to endDate: Date) -> [SavedMeal] {
        getAllMeals().filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    // MARK: - Statistics

    func getAverageCaloriesForWeek() -> Int {
        let today   = Date()
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today) else { return 0 }
        let meals = getMeals(from: weekAgo, to: today)
        let total = meals.reduce(0) { $0 + $1.calories }
        return meals.isEmpty ? 0 : total / 7
    }
}

// MARK: - Notification

extension Notification.Name {
    static let mealsDidUpdate = Notification.Name("mealsDidUpdate")
}
