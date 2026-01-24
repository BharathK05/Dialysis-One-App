//
//  MealInference.swift
//  Dialysis One App
//
//  Created by user@1 on 27/12/25.
//
import Foundation

enum FoodRole {
    case staple
    case gravy
    case drySide
    case accompaniment
    case sweet
    case unknown
}
enum MealResolution {
    case composite(name: String)
    case single(name: String)
}

func resolveMealSafely(from foods: [DetectedFood]) async -> MealResolution {

    // 1️⃣ Rule-based composite detection (FAST & SAFE)
    if isCompositeIndianMeal(foods) {

        // 2️⃣ Try Gemini meal naming (OPTIONAL)
        if let llmName = await MealNamingService.shared.nameMeal(from: foods),
           llmName.count >= 5 {   // prevents "South", "Meal", etc
            return .composite(name: llmName)
        }

        // 3️⃣ Guaranteed fallback
        return .composite(name: "South Indian Vegetarian Meal")
    }

    // 4️⃣ Not a composite → single dish
    let primary = foods.first?.name ?? "Meal"
    return .single(name: primary)
}


func role(for food: DetectedFood) -> FoodRole {
    let type = food.type?.lowercased() ?? ""
    let name = food.name.lowercased()

    if type.contains("rice") || name.contains("rice") {
        return .staple
    }

    if type.contains("curry") || type.contains("gravy") {
        return .gravy
    }

    if type.contains("side") || type.contains("stir") || type.contains("dry") {
        return .drySide
    }

    if name.contains("papad") || name.contains("pickle") {
        return .accompaniment
    }

    if type.contains("dessert") || name.contains("sweet") {
        return .sweet
    }

    return .unknown
}
func isCompositeIndianMeal(_ foods: [DetectedFood]) -> Bool {
    let roles = foods.map { role(for: $0) }

    let staple = roles.contains(.staple)
    let gravy  = roles.filter { $0 == .gravy }.count >= 1
    let dry    = roles.filter { $0 == .drySide }.count >= 1

    return staple && gravy && dry
}
