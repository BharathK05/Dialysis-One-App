//
//  MainWatchView.swift
//  Dialysis One App
//
//  Created by user@22 on 15/12/25.
//

import SwiftUI

struct MainWatchView: View {

    @StateObject private var healthKitManager = HealthKitManager.shared

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 215/255, green: 240/255, blue: 230/255),
                    Color(red: 190/255, green: 225/255, blue: 210/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {

                    Text("Vitals")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.black.opacity(0.85))
                        .padding(.top, 6)

                    // ❤️ Heart Rate
                    vitalsCard(
                        title: "Heart Rate",
                        value: healthKitManager.heartRate.map { "\(Int($0))" } ?? "--",
                        unit: "bpm"
                    )

                    Divider()
                        .background(Color.black.opacity(0.12))
                        .padding(.horizontal, 26)
                        .padding(.vertical, 4)

                    // 🫁 SpO₂
                    vitalsCard(
                        title: "Blood Oxygen",
                        value: healthKitManager.oxygenSaturation.map { "\(Int($0))%" } ?? "-- %",
                        unit: nil
                    )

                    Text(healthKitManager.statusMessage)
                        .font(.system(size: 10))
                        .foregroundColor(Color.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.top, 6)
                        .padding(.bottom, 12)
                }
                .padding(.vertical, 6)
            }
        }
        .onAppear {
            healthKitManager.requestAuthorization()
        }
    }

    // MARK: - Card helper

    private func vitalsCard(title: String, value: String, unit: String?) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Color.black.opacity(0.55))

            Text(value)
                .font(.system(size: 36, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(Color.black.opacity(0.95))

            if let unit = unit {
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 245/255, green: 255/255, blue: 250/255).opacity(0.85))
        )
        .padding(.horizontal, 10)
    }
}
