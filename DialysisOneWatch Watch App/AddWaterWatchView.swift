import SwiftUI

struct AddWaterWatchView: View {

    @State private var selectedType = "Water"
    @State private var selectedQty = 150

    private let types = ["Water", "Coffee", "Tea", "Juice"]
    private let quantities = [50, 75, 100, 125, 150, 200, 250]

    var body: some View {
        VStack(spacing: 12) {

            Picker("Type", selection: $selectedType) {
                ForEach(types, id: \.self) {
                    Text($0)
                }
            }

            Picker("Quantity", selection: $selectedQty) {
                ForEach(quantities, id: \.self) {
                    Text("\($0) ml")
                }
            }

            Text("Custom amounts\nuse iPhone app")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Save") {
                WatchConnectivityManager.shared.sendAddWater(
                    type: selectedType,
                    quantity: selectedQty
                )
            }
        }
        .padding()
    }
}
