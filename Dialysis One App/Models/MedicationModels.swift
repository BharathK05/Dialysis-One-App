//
//  MedicationModels.swift
//  Dialysis One App
//
//  Created by user@1 on 20/11/25.
//

import Foundation
import Combine
import Foundation

enum TimeOfDay: String, CaseIterable, Codable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case night = "Night"
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .night: return "moon.stars.fill"
        }
    }
    
    static func current(for date: Date = Date()) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<12: return .morning
        case 12..<17: return .afternoon
        default: return .night
        }
    }
}

struct Medication: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var times: [TimeOfDay]
    var dosage: String
    private var takenDates: Set<String> // Format: "YYYY-MM-DD-morning"
    
    init(id: UUID = UUID(), name: String, description: String, times: [TimeOfDay], dosage: String) {
        self.id = id
        self.name = name
        self.description = description
        self.times = times
        self.dosage = dosage
        self.takenDates = []
    }
    
    func isTaken(on date: Date, timeOfDay: TimeOfDay) -> Bool {
        let key = dateKey(for: date, timeOfDay: timeOfDay)
        return takenDates.contains(key)
    }
    
    mutating func setTaken(_ taken: Bool, on date: Date, timeOfDay: TimeOfDay) {
        let key = dateKey(for: date, timeOfDay: timeOfDay)
        if taken {
            takenDates.insert(key)
        } else {
            takenDates.remove(key)
        }
    }
    
    private func dateKey(for date: Date, timeOfDay: TimeOfDay) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: date))-\(timeOfDay.rawValue)"
    }
}

// MARK: - Medication Store

class MedicationStore: ObservableObject {
    static let shared = MedicationStore()
    
    @Published private(set) var medications: [Medication] = []
    private let storageKey = "SavedMedications"
    
    init() {
        loadMedications()
        
        // Sample data for testing
        if medications.isEmpty {
            medications = [
                Medication(name: "Tablet 2", description: "Description of Tablet 2", times: [.morning, .afternoon], dosage: "10mg"),
                Medication(name: "Tablet 4", description: "Description of Tablet 4", times: [.afternoon], dosage: "5mg"),
                Medication(name: "Tablet 5", description: "Description of Tablet 5", times: [.morning, .night], dosage: "20mg")
            ]
            saveMedications()
        }
    }
    
    func toggleTaken(medicationId: UUID, date: Date, timeOfDay: TimeOfDay) {
        guard let index = medications.firstIndex(where: { $0.id == medicationId }) else { return }
        let currentStatus = medications[index].isTaken(on: date, timeOfDay: timeOfDay)
        medications[index].setTaken(!currentStatus, on: date, timeOfDay: timeOfDay)
        saveMedications()
    }
    
    func medicationsFor(timeOfDay: TimeOfDay, date: Date = Date()) -> [Medication] {
        return medications.filter { $0.times.contains(timeOfDay) }
    }
    
    func takenCount(for timeOfDay: TimeOfDay, date: Date = Date()) -> (taken: Int, total: Int) {
        let meds = medicationsFor(timeOfDay: timeOfDay, date: date)
        let taken = meds.filter { $0.isTaken(on: date, timeOfDay: timeOfDay) }.count
        let total = meds.count
        return (taken: taken, total: total)
    }
    
    func totalProgress(date: Date = Date()) -> (taken: Int, total: Int) {
        let allTimesOfDay = TimeOfDay.allCases
        var totalTaken = 0      // ← Changed variable name
        var totalMedications = 0  // ← Changed variable name
        
        for time in allTimesOfDay {
            let progress = takenCount(for: time, date: date)
            totalTaken += progress.taken
            totalMedications += progress.total
        }
        
        return (taken: totalTaken, total: totalMedications)
    }
    
    private func saveMedications() {
        if let encoded = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadMedications() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            medications = decoded
        }
    }
}
