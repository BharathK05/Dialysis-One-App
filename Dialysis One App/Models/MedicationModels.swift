//
//  MedicationModels.swift
//  Dialysis One App
//
//  Medication list & adherence.
//  The medication LIST (names/dosages/schedule) persists in UserDefaults.
//  Medication ADHERENCE is fully backed by ActivityLogManager (SwiftData).
//  takenDates has been removed — isTaken and toggleTaken go through SwiftData.
//

import Foundation
import Combine

enum TimeOfDay: String, CaseIterable, Codable {
    case morning   = "Morning"
    case afternoon = "Afternoon"
    case night     = "Night"

    var icon: String {
        switch self {
        case .morning:   return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .night:     return "moon.stars.fill"
        }
    }

    static func current(for date: Date = Date()) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<12: return .morning
        case 12..<17: return .afternoon
        default:     return .night
        }
    }
}

// MARK: - Medication (definition only — no adherence state)

struct Medication: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var times: [TimeOfDay]
    var dosage: String

    init(id: UUID = UUID(), name: String, description: String, times: [TimeOfDay], dosage: String) {
        self.id          = id
        self.name        = name
        self.description = description
        self.times       = times
        self.dosage      = dosage
    }

    /// Queries ActivityLogManager — source of truth for adherence.
    func isTaken(on date: Date, timeOfDay: TimeOfDay) -> Bool {
        ActivityLogManager.shared.isMedicationTaken(
            medicationId: id,
            timeSlot:     timeOfDay.rawValue,
            date:         date
        )
    }
}

// MARK: - MedicationStore

class MedicationStore: ObservableObject {
    static let shared = MedicationStore()

    @Published private(set) var medications: [Medication] = []
    private let storageKey = "SavedMedications"

    init() {
        loadMedications()
    }

    func addMedication(_ medication: Medication) {
        medications.append(medication)
        saveMedications()
    }

    /// Toggles taken/not-taken via ActivityLogManager (SwiftData).
    func toggleTaken(medicationId: UUID, date: Date, timeOfDay: TimeOfDay) {
        guard let medication = medications.first(where: { $0.id == medicationId }) else { return }
        let current = medication.isTaken(on: date, timeOfDay: timeOfDay)
        ActivityLogManager.shared.setMedicationTaken(
            medicationId: medicationId,
            name:         medication.name,
            dosage:       medication.dosage,
            timeSlot:     timeOfDay.rawValue,
            date:         date,
            taken:        !current
        )
        // Notify observers so UI refreshes
        objectWillChange.send()
    }

    func deleteMedication(id: UUID) {
        medications.removeAll { $0.id == id }
        saveMedications()
    }

    func medicationsFor(timeOfDay: TimeOfDay, date: Date = Date()) -> [Medication] {
        medications.filter { $0.times.contains(timeOfDay) }
    }

    func takenCount(for timeOfDay: TimeOfDay, date: Date = Date()) -> (taken: Int, total: Int) {
        let meds  = medicationsFor(timeOfDay: timeOfDay, date: date)
        let taken = meds.filter { $0.isTaken(on: date, timeOfDay: timeOfDay) }.count
        return (taken: taken, total: meds.count)
    }

    func totalProgress(date: Date = Date()) -> (taken: Int, total: Int) {
        var totalTaken = 0
        var totalMeds  = 0
        for time in TimeOfDay.allCases {
            let p = takenCount(for: time, date: date)
            totalTaken += p.taken
            totalMeds  += p.total
        }
        return (taken: totalTaken, total: totalMeds)
    }

    // MARK: - Medication list persistence (definition only)

    private func saveMedications() {
        if let encoded = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadMedications() {
        if let data    = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            medications = decoded
        }
    }
}
