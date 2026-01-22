import SwiftUI
import WatchKit

struct AddMedicationWatchView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 🌿 Same background as Home
            LinearGradient(
                colors: [
                    Color(red: 215/255, green: 240/255, blue: 230/255),
                    Color(red: 190/255, green: 225/255, blue: 210/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {

                medicationButton(title: "Morning")
                medicationButton(title: "Afternoon")
                medicationButton(title: "Night")
            }
            .padding()
        }
        .navigationTitle("Medication")
    }

    private func medicationButton(title: String) -> some View {
        Button {
            WatchConnectivityManager.shared.sendAddMedication(timeOfDay: title.lowercased())

            WKInterfaceDevice.current().play(.success)
            dismiss()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.9))
                )
        }
        .buttonStyle(.plain)
    }
}
