//
//  Appointments.swift
//  Dialysis One App
//
//  Created by user@22 on 25/11/25.
//

import Foundation

struct Appointment: Codable, Identifiable {
    let id: UUID
    let hospitalName: String
    let date: Date
    let notes: String?
}

