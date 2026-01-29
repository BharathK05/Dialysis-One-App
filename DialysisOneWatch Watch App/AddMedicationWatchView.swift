//
//  AddMedicationWatchView.swift
//  Dialysis One App
//
//  Created by user@22 on 17/12/25.
//


import SwiftUI
import WatchKit

struct AddMedicationWatchView: View {

    @StateObject private var data = WatchDataManager.shared
    @Environment(\.dismiss) private var dismiss

    private let times = ["morning", "afternoon", "night"]
    
        


    var body: some View {
        VStack(spacing: 10) {

            Picker("Time", selection: $data.selectedTimeOfDay) {
                ForEach(times, id: \.self) {
                    Text($0.capitalized)
                }
            }
            .pickerStyle(.wheel)

            if data.medications.isEmpty {
                Text("No medications")
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(data.medications) { med in
                            Button {
                                WatchConnectivityManager.shared.sendAddMedication(
                                    medicationId: med.id,
                                    timeOfDay: data.selectedTimeOfDay
                                )

                                WKInterfaceDevice.current().play(.success)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(med.name)
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(med.dosage)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: med.isTaken ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(med.isTaken ? .green : .gray)
                                }
                            }
                            .disabled(med.isTaken)
                            .opacity(med.isTaken ? 0.5 : 1.0)
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding()
    }
}
