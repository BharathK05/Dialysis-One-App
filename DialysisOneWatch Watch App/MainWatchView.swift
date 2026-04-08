//
//  MainWatchView.swift
//  Dialysis One App
//
//  Created by user@22 on 16/12/25.
//

import SwiftUI

struct MainWatchView: View {

    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @Environment(\.colorScheme) var colorScheme


    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {

                Text("Vitals")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.85))
                    .padding(.top, 6)

                // Heart Rate
                vitalsCard(
                    title: "Heart Rate",
                    value: healthKitManager.heartRate.map { "\(Int($0))" } ?? "--",
                    unit: "bpm"
                )

                Divider()
                    .background(Color.primary.opacity(0.12))
                    .padding(.horizontal, 26)
                    .padding(.vertical, 4)

                // SpO₂
                vitalsCard(
                    title: "Blood Oxygen",
                    value: healthKitManager.oxygenSaturation != nil
                        ? "\(Int(healthKitManager.oxygenSaturation!))%"
                        : "Measured periodically",
                    unit: nil,
                    isSecondary: healthKitManager.oxygenSaturation == nil
                )


                Text(healthKitManager.statusMessage)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
            }
            .padding(.vertical, 6)
        }
        .watchBackground()
        .onAppear {
            healthKitManager.requestAuthorization { _ in }
        }
    }

    // MARK: - Card helper

    private func vitalsCard(
        title: String,
        value: String,
        unit: String?,
        isSecondary: Bool = false
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text(value)
                .font(
                    isSecondary
                    ? .system(size: 14, weight: .medium)
                    : .system(size: 36, weight: .semibold)
                )
                .multilineTextAlignment(.center)
                .foregroundColor(.primary.opacity(0.9))

            if let unit {
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(WatchTheme.cardBackground(for: colorScheme))
        )
        .padding(.horizontal, 10)
    }

}
