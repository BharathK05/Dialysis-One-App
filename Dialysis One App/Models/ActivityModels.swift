//
//  ActivityModels.swift
//  Dialysis One App
//
//  SwiftData models for time-series activity data.
//  These are SEPARATE from UserProfile (which holds configuration).
//  All logs are append-only; never mix with UserProfile.
//

import Foundation
import SwiftData

// MARK: - FoodLog

@Model
final class FoodLog {
    var id: UUID
    var dishName: String
    var mealType: String          // "Breakfast" | "Lunch" | "Dinner"
    var calories: Int
    var protein: Double
    var potassium: Int
    var sodium: Int
    var quantity: Int
    var timestamp: Date
    var imageData: Data?

    init(
        id: UUID = UUID(),
        dishName: String,
        mealType: String,
        calories: Int,
        protein: Double,
        potassium: Int,
        sodium: Int,
        quantity: Int,
        timestamp: Date = Date(),
        imageData: Data? = nil
    ) {
        self.id = id
        self.dishName = dishName
        self.mealType = mealType
        self.calories = calories
        self.protein = protein
        self.potassium = potassium
        self.sodium = sodium
        self.quantity = quantity
        self.timestamp = timestamp
        self.imageData = imageData
    }
}

// MARK: - FluidLog

@Model
final class FluidLog {
    var id: UUID
    var type: String              // "Water" | "Coffee" | "Tea" | "Juice"
    var quantity: Int             // ml
    var timestamp: Date

    init(
        id: UUID = UUID(),
        type: String,
        quantity: Int,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.quantity = quantity
        self.timestamp = timestamp
    }
}

// MARK: - MedicationLog

@Model
final class MedicationLog {
    var id: UUID
    /// Composite key: "<medicationId>-<timeSlot>-<yyyy-MM-dd>"
    /// Used for fast equality lookups in predicates without UUID comparison.
    var lookupKey: String
    var medicationName: String
    var dosage: String
    var timeSlot: String          // "Morning" | "Afternoon" | "Night"
    var isTaken: Bool
    var dateKey: String           // "yyyy-MM-dd" – for date-scoped queries
    var timestamp: Date

    init(
        id: UUID = UUID(),
        lookupKey: String,
        medicationName: String,
        dosage: String,
        timeSlot: String,
        isTaken: Bool,
        dateKey: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.lookupKey = lookupKey
        self.medicationName = medicationName
        self.dosage = dosage
        self.timeSlot = timeSlot
        self.isTaken = isTaken
        self.dateKey = dateKey
        self.timestamp = timestamp
    }
}
