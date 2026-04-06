//
//  ActivityLogManager.swift
//  Dialysis One App
//
//  Central manager for all user activity logs (food, fluid, medication).
//  All methods are assumed to be called from the main thread.
//  Uses ProfileManager's shared ModelContext — call only after
//  ProfileManager.initializeContainer() has run.
//

import Foundation
import SwiftData

// MARK: - ActivityLogManager

final class ActivityLogManager {

    static let shared = ActivityLogManager()
    private init() {}

    // Lazily resolved from ProfileManager – available after initializeContainer()
    private var context: ModelContext? { ProfileManager.shared.context }

    // MARK: - Date helpers

    private let dayKeyFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private func dayBounds(for date: Date) -> (start: Date, end: Date) {
        let start = Calendar.current.startOfDay(for: date)
        let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    private func dayKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    // MARK: - Food Logs

    func saveFoodLog(
        id: UUID = UUID(),
        dishName: String,
        mealType: String,
        calories: Int,
        protein: Double,
        potassium: Int,
        sodium: Int,
        quantity: Int,
        imageData: Data?,
        timestamp: Date = Date()
    ) {
        guard let context else { return }
        let log = FoodLog(
            id: id, dishName: dishName, mealType: mealType,
            calories: calories, protein: protein,
            potassium: potassium, sodium: sodium,
            quantity: quantity, timestamp: timestamp, imageData: imageData
        )
        context.insert(log)
        try? context.save()
    }

    func foodLogs(for date: Date = Date()) -> [FoodLog] {
        guard let context else { return [] }
        let (start, end) = dayBounds(for: date)
        var desc = FetchDescriptor<FoodLog>(
            predicate: #Predicate { $0.timestamp >= start && $0.timestamp < end },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        desc.fetchLimit = 500
        return (try? context.fetch(desc)) ?? []
    }

    func allFoodLogs() -> [FoodLog] {
        guard let context else { return [] }
        let desc = FetchDescriptor<FoodLog>(sortBy: [SortDescriptor(\.timestamp)])
        return (try? context.fetch(desc)) ?? []
    }

    /// Fetch food logs within an arbitrary date range (inclusive of start, exclusive of end)
    func foodLogs(from start: Date, to end: Date) -> [FoodLog] {
        guard let context else { return [] }
        var desc = FetchDescriptor<FoodLog>(
            predicate: #Predicate { $0.timestamp >= start && $0.timestamp < end },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        desc.fetchLimit = 2000
        return (try? context.fetch(desc)) ?? []
    }

    /// Fetch fluid logs within an arbitrary date range
    func fluidLogs(from start: Date, to end: Date) -> [FluidLog] {
        guard let context else { return [] }
        let desc = FetchDescriptor<FluidLog>(
            predicate: #Predicate { $0.timestamp >= start && $0.timestamp < end },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return (try? context.fetch(desc)) ?? []
    }

    /// Fetch medication logs for a specific dateKey range
    func medicationLogs(dateKeys: [String]) -> [MedicationLog] {
        guard let context else { return [] }
        let desc = FetchDescriptor<MedicationLog>(
            sortBy: [SortDescriptor(\.dateKey)]
        )
        let all = (try? context.fetch(desc)) ?? []
        let keySet = Set(dateKeys)
        return all.filter { keySet.contains($0.dateKey) }
    }

    /// Convenience: nutrient totals for an arbitrary date
    func nutrientTotals(for date: Date) -> (calories: Int, potassium: Int, sodium: Int, protein: Int) {
        let logs = foodLogs(for: date)
        return (
            calories:  logs.reduce(0)   { $0 + $1.calories },
            potassium: logs.reduce(0)   { $0 + $1.potassium },
            sodium:    logs.reduce(0)   { $0 + $1.sodium },
            protein:   Int(logs.reduce(0.0) { $0 + $1.protein })
        )
    }

    /// Convenience: fluid total for an arbitrary date
    func fluidTotal(for date: Date) -> Int {
        fluidLogs(for: date).reduce(0) { $0 + $1.quantity }
    }

    func deleteFoodLog(id: UUID) {
        guard let context else { return }
        let idStr = id.uuidString
        let desc = FetchDescriptor<FoodLog>(predicate: #Predicate { $0.id.uuidString == idStr })
        if let log = try? context.fetch(desc).first {
            context.delete(log)
            try? context.save()
        }
    }

    func clearAllFoodLogs() {
        guard let context else { return }
        let desc = FetchDescriptor<FoodLog>()
        if let logs = try? context.fetch(desc) {
            logs.forEach { context.delete($0) }
            try? context.save()
        }
    }

    func todayNutrientTotals() -> (calories: Int, potassium: Int, sodium: Int, protein: Int) {
        let logs = foodLogs(for: Date())
        return (
            calories:  logs.reduce(0)   { $0 + $1.calories },
            potassium: logs.reduce(0)   { $0 + $1.potassium },
            sodium:    logs.reduce(0)   { $0 + $1.sodium },
            protein:   Int(logs.reduce(0.0) { $0 + $1.protein })
        )
    }

    // MARK: - Fluid Logs

    func saveFluidLog(type: String, quantity: Int, timestamp: Date = Date()) {
        guard let context else { return }
        let log = FluidLog(type: type, quantity: quantity, timestamp: timestamp)
        context.insert(log)
        try? context.save()
    }

    func fluidLogs(for date: Date = Date()) -> [FluidLog] {
        guard let context else { return [] }
        let (start, end) = dayBounds(for: date)
        let desc = FetchDescriptor<FluidLog>(
            predicate: #Predicate { $0.timestamp >= start && $0.timestamp < end },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return (try? context.fetch(desc)) ?? []
    }

    func todayFluidTotal() -> Int {
        fluidLogs(for: Date()).reduce(0) { $0 + $1.quantity }
    }

    func totalFluid(for date: Date) -> Int {
        fluidLogs(for: date).reduce(0) { $0 + $1.quantity }
    }

    // MARK: - Medication Logs

    func setMedicationTaken(
        medicationId: UUID,
        name: String,
        dosage: String,
        timeSlot: String,
        date: Date,
        taken: Bool
    ) {
        guard let context else { return }
        let dk  = dayKey(for: date)
        let key = "\(medicationId.uuidString)-\(timeSlot)-\(dk)"

        let desc = FetchDescriptor<MedicationLog>(
            predicate: #Predicate { $0.lookupKey == key }
        )

        if let existing = try? context.fetch(desc).first {
            existing.isTaken   = taken
            existing.timestamp = Date()
        } else {
            let log = MedicationLog(
                lookupKey:      key,
                medicationName: name,
                dosage:         dosage,
                timeSlot:       timeSlot,
                isTaken:        taken,
                dateKey:        dk
            )
            context.insert(log)
        }
        try? context.save()
    }

    func isMedicationTaken(medicationId: UUID, timeSlot: String, date: Date = Date()) -> Bool {
        guard let context else { return false }
        let dk  = dayKey(for: date)
        let key = "\(medicationId.uuidString)-\(timeSlot)-\(dk)"
        let desc = FetchDescriptor<MedicationLog>(
            predicate: #Predicate { $0.lookupKey == key }
        )
        return (try? context.fetch(desc).first?.isTaken) ?? false
    }

    func medicationLogs(for date: Date = Date()) -> [MedicationLog] {
        guard let context else { return [] }
        let dk = dayKey(for: date)
        let desc = FetchDescriptor<MedicationLog>(
            predicate: #Predicate { $0.dateKey == dk }
        )
        return (try? context.fetch(desc)) ?? []
    }
}
