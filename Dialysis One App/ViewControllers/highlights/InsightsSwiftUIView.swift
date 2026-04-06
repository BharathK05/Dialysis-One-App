//
//  InsightsSwiftUIView.swift
//  Dialysis One App
//
//  Dense, glanceable Apple Health-style highlight cards.
//  Uses SwiftUI for maximum density and clean layout.
//

import SwiftUI

// MARK: - Container

struct InsightsSwiftUIList: View {
    let reports: [InsightReport]
    let onCardTapped: (InsightReport) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(reports, id: \.title) { report in
                InsightSwiftUICard(report: report) {
                    onCardTapped(report)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Card

struct InsightSwiftUICard: View {
    let report: InsightReport
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 0) {
                // Left accent bar
                Rectangle()
                    .fill(Color(report.accentColor))
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Top row: Icon + Title
                    HStack(spacing: 6) {
                        Image(systemName: report.category.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(report.accentColor))
                        
                        Text(report.title.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .default))
                            .tracking(0.5)
                            .foregroundColor(Color(report.accentColor))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(alignment: .bottom, spacing: 12) {
                        // Main Value + Subtext block
                        VStack(alignment: .leading, spacing: 2) {
                            Text(report.primaryValue)
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(report.accentColor))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            Text(report.primaryLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer(minLength: 8)
                        
                        // Sparkline
                        if report.graphData.values.count > 1 {
                            SparklineShape(values: report.graphData.values)
                                .stroke(Color(report.accentColor).opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .frame(width: 60, height: 28)
                                .padding(.bottom, 4)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(isPressed ? 0.02 : 0.06), radius: isPressed ? 4 : 8, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(CardButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Button Style for tracking press state

struct CardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                withAnimation { isPressed = newValue }
            }
    }
}

// MARK: - Sparkline Shape

struct SparklineShape: Shape {
    let values: [Double]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        
        let maxV = values.max() ?? 1
        let minV = values.min() ?? 0
        let range = maxV - minV > 0 ? maxV - minV : 1
        let stepX = rect.width / CGFloat(values.count - 1)
        
        for (i, v) in values.enumerated() {
            let x = CGFloat(i) * stepX
            let y = rect.height - rect.height * CGFloat((v - minV) / range)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}
