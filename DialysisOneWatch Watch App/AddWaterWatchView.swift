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

    private let types = ["Water", "Coffee", "Tea", "Juice"]
    private let quantities = [50, 75, 100, 125, 150, 200, 250]

    var body: some View {
        ZStack {
            // 🌿 Background (same as Home)
            LinearGradient(
                colors: [
                    Color(red: 215/255, green: 240/255, blue: 230/255),
                    Color(red: 190/255, green: 225/255, blue: 210/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Form {

                // TYPE
                Section {
                    Picker(selection: $selectedType) {
                        ForEach(types, id: \.self) {
                            Text($0)
                                .foregroundColor(.black)
                        }
                    } label: {
                        EmptyView()
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.85))
                    )
                } header: {
                    Text("Type")
                        .foregroundColor(.black)
                }

                // QUANTITY
                Section {
                    Picker(selection: $selectedQty) {
                        ForEach(quantities, id: \.self) {
                            Text("\($0) ml")
                                .foregroundColor(.black)
                        }
                    } label: {
                        EmptyView()
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.85))
                    )
                } header: {
                    Text("Quantity (ml)")
                        .foregroundColor(.black)
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
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                    }
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.9))
                )

                // INFO TEXT (not inside card)
                Section {
                    Text("To add Custom Quantity\nuse Dialysis One iPhone App")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)

                
            }
            .scrollContentBackground(.hidden)
            .tint(.black)
        }
    }
}
