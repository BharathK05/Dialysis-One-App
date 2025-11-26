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
        // Realistic CKD medication data
        if medications.isEmpty {
            medications = [
                // Phosphate Binders
                Medication(
                    name: "Calcium Acetate",
                    description: "Phosphate binder - Take with meals",
                    times: [.morning, .afternoon, .night],
                    dosage: "667mg"
                ),
                
                // Blood Pressure
                Medication(
                    name: "Amlodipine",
                    description: "Blood pressure medication",
                    times: [.morning],
                    dosage: "5mg"
                ),
                
                // Diuretic
                Medication(
                    name: "Furosemide",
                    description: "Diuretic - Helps remove extra fluid",
                    times: [.morning],
                    dosage: "40mg"
                ),
                
                // Potassium Binder
                Medication(
                    name: "Sodium Polystyrene",
                    description: "Helps control potassium levels",
                    times: [.morning, .night],
                    dosage: "15g"
                ),
                
                // Anemia Management
                Medication(
                    name: "Ferrous Sulfate",
                    description: "Iron supplement for anemia",
                    times: [.afternoon],
                    dosage: "325mg"
                ),
                
                // Vitamin D
                Medication(
                    name: "Calcitriol",
                    description: "Active Vitamin D supplement",
                    times: [.morning],
                    dosage: "0.25mcg"
                ),
                
                // Another Phosphate Binder
                Medication(
                    name: "Sevelamer",
                    description: "Non-calcium phosphate binder",
                    times: [.morning, .afternoon, .night],
                    dosage: "800mg"
                )
            ]
            saveMedications()
        }
    }
    // Add this method to MedicationStore:
    func addMedication(_ medication: Medication) {
        medications.append(medication)
        saveMedications()
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
        var totalTaken = 0
        var totalMedications = 0
        
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
