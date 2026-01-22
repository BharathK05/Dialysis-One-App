//
//  SummaryCard.swift
//  Dialysis One App
//
//  Created by user@22 on 15/12/25.
//


import SwiftUI

struct SummaryCard: View {
    let title: String
    let subtitle: String?
    let icon: String
    let accent: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black.opacity(0.88))
                Text(subtitle ?? "—")
                    .font(.system(size: 11))
                    .foregroundColor(.black.opacity(0.55))
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 245/255, green: 255/255, blue: 250/255).opacity(0.94))
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
    }
}

struct HomeView: View {
    @StateObject private var watchData = WatchDataManager.shared

    // card height constant so summary cards are equal height
    private let cardHeight: CGFloat = 58

    var body: some View {
        ZStack {
            // same background as Vitals screen
            LinearGradient(
                colors: [
                    Color(red: 215/255, green: 240/255, blue: 230/255),
                    Color(red: 190/255, green: 225/255, blue: 210/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Scrollable column so content always reachable
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    // Title
                    HStack {
                        Text("Today")
                            .font(.system(size: 22, weight: .bold))   // Bigger + Bold
                            .foregroundColor(.black.opacity(0.90))
                            .padding(.leading, 10)
                            .padding(.top, 4)

                        Spacer()
                    }

                    // SUMMARY HEADER
                    HStack {
                        Text("Summary")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black.opacity(0.75))
                        Spacer()
                    }
                    .padding(.horizontal, 10)

                    // SUMMARY CARDS (stacked vertically, equal height)
                    VStack(spacing: 10) {
                        SummaryCard(title: "Diet",
                                    subtitle: watchData.foodSummary ?? "—",
                                    icon: "fork.knife",
                                    accent: .orange)
                            .frame(height: cardHeight)

                        SummaryCard(title: "Water",
                                    subtitle: watchData.waterSummary ?? "—",
                                    icon: "drop.fill",
                                    accent: .blue)
                            .frame(height: cardHeight)

                        SummaryCard(title: "Medication",
                                    subtitle: watchData.medicationSummary ?? "—",
                                    icon: "pills.fill",
                                    accent: .green)
                            .frame(height: cardHeight)
                    }
                    .padding(.horizontal, 10)

                    // Vitals section below the summary, as you requested
                    VStack(spacing: 8) {
                        HStack {
                            Text("Vitals")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black.opacity(0.85))
                            Spacer()
                        }
                        .padding(.horizontal, 10)

                        NavigationLink(destination: MainWatchView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Vitals")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.85))
                                    Text("Heart rate • SpO₂")
                                        .font(.system(size: 11))
                                        .foregroundColor(.black.opacity(0.55))
                                }

                                Spacer()

                                Image(systemName: "heart.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(red: 245/255, green: 255/255, blue: 250/255).opacity(0.94))
                                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)

                    // small footer text
                    Text("Dialysis One App")
                        .font(.system(size: 10))
                        .foregroundColor(.black.opacity(0.55))
                        .padding(.vertical, 12)
                }
                .padding(.bottom, 16)
            } // ScrollView
        } // ZStack
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
}
#endif
