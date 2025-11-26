//
//  AppointmentStore.swift
//  Dialysis One App
//
//  Created by user@22 on 25/11/25.
//

import Foundation

final class AppointmentStore {

    static let shared = AppointmentStore()
    private init() {}

    private let key = "appointments_list_v1"

    func loadAppointments() -> [Appointment] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Appointment].self, from: data)) ?? []
    }

    func saveAppointments(_ list: [Appointment]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func addAppointment(_ appointment: Appointment) {
        var list = loadAppointments()
        list.append(appointment)
        saveAppointments(list)
    }

    func nextUpcoming() -> Appointment? {
        let now = Date()
        return loadAppointments()
            .filter { $0.date >= now }
            .sorted(by: { $0.date < $1.date })
            .first
    }
    
    func delete(_ id: UUID) {
        var list = loadAppointments()
        list.removeAll { $0.id == id }
        saveAppointments(list)
    }
    
    func updateAppointment(_ updated: Appointment) {
        var list = loadAppointments()
        if let index = list.firstIndex(where: { $0.id == updated.id }) {
            list[index] = updated
            saveAppointments(list)
        }
    }


}

