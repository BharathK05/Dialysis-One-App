//
//  InsightReport.swift
//  Dialysis One App
//
//  Structured output model from InsightDataEngine.
//  All fields are computed — no hardcoded values.
//

import UIKit

// MARK: - Time Window

enum InsightTimeWindow: Int, CaseIterable {
    case week     = 7
    case month    = 30
    case sixMonths = 180
    case year     = 365

    var segmentTitle: String {
        switch self {
        case .week:       return "W"
        case .month:      return "M"
        case .sixMonths:  return "6M"
        case .year:       return "Y"
        }
    }

    var displayName: String {
        switch self {
        case .week:       return "week"
        case .month:      return "month"
        case .sixMonths:  return "6 months"
        case .year:       return "year"
        }
    }
}

// MARK: - Trend Direction

enum InsightTrend {
    case improved
    case decreased
    case unchanged

    var symbol: String {
        switch self {
        case .improved:   return "↑"
        case .decreased:  return "↓"
        case .unchanged:  return "→"
        }
    }

    var color: UIColor {
        switch self {
        case .improved:   return .systemGreen
        case .decreased:  return .systemOrange
        case .unchanged:  return .systemBlue
        }
    }

    /// Whether "improved" is the positive direction (true for adherence, false for limits exceeded)
    var isPositive: Bool { self == .improved }
}

// MARK: - Graph Data

struct InsightGraphData {
    let values: [Double]          // parallel arrays — one entry per day/period
    let labels: [String]          // x-axis labels (e.g. "Mon", "Jan")
    let goalValue: Double?        // optional horizontal goal line
    let unit: String              // "%" or "ml" or "mg"

    static let empty = InsightGraphData(values: [], labels: [], goalValue: nil, unit: "")
}

// MARK: - Heatmap Data

struct InsightHeatmapData {
    struct Cell {
        let date: Date
        let value: Double       // 0.0–1.0 intensity
        let label: String       // day number "1"–"31"
    }
    let cells: [Cell]
    let startDate: Date
    let endDate: Date
}

// MARK: - Secondary Metric

struct SecondaryMetric {
    let label: String    // e.g. "Average Daily"
    let value: String    // e.g. "1 800 ml"
    let iconName: String // SF Symbol
}

// MARK: - Insight Report

struct InsightReport {
    /// Category this report belongs to
    let category: HealthInsight.InsightCategory

    /// E.g. "Medication Adherence", "Fluid Intake", "Potassium"
    let title: String

    /// The BIG central number or value  — e.g. "70%", "6", "1 840 ml"
    let primaryValue: String

    /// Label underneath the primary value — e.g. "Weekly Adherence", "Avg per day"
    let primaryLabel: String

    /// Trend vs previous same-length window
    let trend: InsightTrend

    /// Absolute % change vs previous period  (always positive; direction encoded in trend)
    let trendDelta: Double

    /// Human-readable comparison — e.g. "10% lower than last week"  (computed, never hardcoded)
    let comparisonText: String

    /// Dynamic time label — e.g. "Past 7 days" or "Past 12 days" if sparse
    let timeRangeLabel: String

    /// Data for the primary chart
    let graphData: InsightGraphData

    /// Optional heatmap (medication adherence only)
    let heatmapData: InsightHeatmapData?

    /// Secondary stat rows (shown below the graph)
    let secondaryMetrics: [SecondaryMetric]

    /// Auto-generated 2–3 sentence summary paragraph
    let summaryText: String

    /// Feature screen to navigate to on CTA tap
    let actionScreen: HealthInsight.DestinationScreen

    // MARK: - Derived UI helpers

    var trendBadgeText: String {
        let sign  = trend.symbol
        let delta = String(format: "%.0f%%", trendDelta)
        return "\(sign) \(delta)"
    }

    var accentColor: UIColor { category.color }
}

// MARK: - Medication Computed Data

struct MedicationInsightData {
    let totalDoses:      Int
    let takenDoses:      Int
    let missedDoses:     Int
    let adherencePct:    Double           // 0–100
    let dailyAdherence:  [(date: Date, pct: Double)]
    let trend:           InsightTrend
    let trendDelta:      Double
    let previousPct:     Double
    let actualDays:      Int             // actual days with data (may be < window)
}

// MARK: - Fluid Computed Data

struct FluidInsightData {
    let dailyIntake:     [(date: Date, ml: Int)]
    let averageDaily:    Int              // ml
    let goalMl:          Int
    let goalPct:         Double           // 0–100 (average vs goal)
    let consistencyDays: Int             // days ≥ 80% of goal
    let trend:           InsightTrend
    let trendDelta:      Double
    let previousAvg:     Int
    let actualDays:      Int
}

// MARK: - Nutrient Computed Data

struct NutrientInsightData {
    struct DailyNutrient {
        let date:      Date
        let calories:  Int
        let potassium: Int
        let sodium:    Int
        let protein:   Int
    }

    let daily:             [DailyNutrient]
    let avgCalories:       Int
    let avgPotassium:      Int
    let avgSodium:         Int
    let avgProtein:        Int

    let calorieCompliance:   Double   // % of days within calorie limit
    let potassiumCompliance: Double
    let sodiumCompliance:    Double
    let proteinCompliance:   Double

    let trend:     InsightTrend
    let trendDelta: Double
    let actualDays: Int
}
