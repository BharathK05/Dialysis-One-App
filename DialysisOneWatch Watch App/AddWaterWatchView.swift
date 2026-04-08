//
//  AddWaterWatchView.swift
//  Dialysis One App
//
//  Created by user@22 on 17/12/25.
//


import SwiftUI
import WatchKit

struct AddWaterWatchView: View {

    @State private var selectedType = "Water"
    @State private var selectedQty = 150
    @State private var isSaving = false

    @Environment(\.dismiss) private var dismiss

    @Environment(\.colorScheme) var colorScheme
    private let types = ["Water", "Coffee", "Tea", "Juice"]
    private let quantities = [50, 75, 100, 125, 150, 200, 250]

    var body: some View {
        Form {
            // TYPE
            Section {
                Picker(selection: $selectedType) {
                    ForEach(types, id: \.self) {
                        Text($0)
                            .foregroundColor(.primary)
                    }
                } label: {
                    EmptyView()
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(WatchTheme.cardBackground(for: colorScheme))
                )
            } header: {
                Text("Type")
                    .foregroundColor(.secondary)
            }

            // QUANTITY
            Section {
                Picker(selection: $selectedQty) {
                    ForEach(quantities, id: \.self) {
                        Text("\($0) ml")
                            .foregroundColor(.primary)
                    }
                } label: {
                    EmptyView()
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(WatchTheme.cardBackground(for: colorScheme))
                )
            } header: {
                Text("Quantity (ml)")
                    .foregroundColor(.secondary)
            }
            
            // SAVE BUTTON
            Section {
                Button {
                    guard !isSaving else { return }
                    isSaving = true

                    WatchConnectivityManager.shared.sendAddWater(
                        type: selectedType,
                        quantity: selectedQty
                    )

                    WKInterfaceDevice.current().play(.success)
                    dismiss()
                } label: {
                    Text("Save")
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: 16)
                    .fill(WatchTheme.cardBackground(for: colorScheme))
            )

            // INFO TEXT (not inside card)
            Section {
                Text("To add Custom Quantity\nuse Dialysis One iPhone App")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .tint(.primary)
        .watchBackground()
    }
}
