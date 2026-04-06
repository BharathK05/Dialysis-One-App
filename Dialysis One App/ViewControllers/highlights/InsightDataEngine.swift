//
//  InsightDataEngine.swift
//  Dialysis One App
//
//  Deterministic metric computation engine.
//  All results derived from SwiftData logs — no LLM, no hardcoded values.
//

import Foundation

// MARK: - InsightDataEngine

final class InsightDataEngine {
    static let shared = InsightDataEngine()
    private init() {}

    private let cal = Calendar.current

    // MARK: - Public API

    /// Compute medication adherence for the given window.
    func medicationInsight(window: InsightTimeWindow) -> MedicationInsightData {
        let today  = Date()
        let days   = window.rawValue
        let dates  = pastDates(count: days, endingOn: today)
        let prevDates = pastDates(count: days, endingOn: dates.first ?? today)

        let store  = MedicationStore.shared
        let allMeds = store.medications

        func adherence(for dates: [Date]) -> (taken: Int, total: Int, daily: [(date: Date, pct: Double)]) {
            var totalTaken = 0
            var totalDoses = 0
            var daily: [(date: Date, pct: Double)] = []

            for date in dates {
                var dayTaken = 0
                var dayTotal = 0
                for tod in TimeOfDay.allCases {
                    let meds = allMeds.filter { $0.times.contains(tod) }
                    dayTotal += meds.count
                    dayTaken += meds.filter { $0.isTaken(on: date, timeOfDay: tod) }.count
                }
                let pct = dayTotal > 0 ? Double(dayTaken) / Double(dayTotal) * 100 : 0
                daily.append((date: date, pct: pct))
                totalTaken += dayTaken
                totalDoses += dayTotal
            }
            return (totalTaken, totalDoses, daily)
        }

        let curr = adherence(for: dates)
        let prev = adherence(for: prevDates)

        let currPct = curr.total > 0 ? Double(curr.taken) / Double(curr.total) * 100 : 0
        let prevPct = prev.total > 0 ? Double(prev.taken) / Double(prev.total) * 100 : 0
        let delta   = abs(currPct - prevPct)
        let trend   = trendDirection(current: currPct, previous: prevPct, higherIsBetter: true)

        return MedicationInsightData(
            totalDoses:     curr.total,
            takenDoses:     curr.taken,
            missedDoses:    curr.total - curr.taken,
            adherencePct:   currPct,
            dailyAdherence: curr.daily,
            trend:          trend,
            trendDelta:     delta,
            previousPct:    prevPct,
            actualDays:     dates.count
        )
    }

    /// Build an InsightReport for medication adherence.
    func medicationReport(window: InsightTimeWindow) -> InsightReport {
        let data = medicationInsight(window: window)
        let windowLabel = timeRangeLabel(days: data.actualDays, window: window)

        let pctStr = String(format: "%.0f%%", data.adherencePct)
        let primaryLabel = "Adherence"

        // Graph: daily adherence %
        let graphValues = data.dailyAdherence.map { $0.pct }
        let graphLabels = data.dailyAdherence.map { shortDayLabel($0.date) }
        let graphData   = InsightGraphData(
            values:    graphValues,
            labels:    graphLabels,
            goalValue: 80,        // 80% adherence goal
            unit:      "%"
        )

        // Heatmap (medication only)
        let heatmap = buildHeatmap(from: data.dailyAdherence.map { ($0.date, $0.pct / 100) })

        // Secondary metrics
        let secondary: [SecondaryMetric] = [
            SecondaryMetric(label: "Doses Taken", value: "\(data.takenDoses)", iconName: "checkmark.circle"),
            SecondaryMetric(label: "Doses Missed", value: "\(data.missedDoses)", iconName: "xmark.circle"),
            SecondaryMetric(label: "Total Scheduled", value: "\(data.totalDoses)", iconName: "calendar"),
        ]

        let summary = buildMedicationSummary(data: data, windowLabel: windowLabel)
        let comparison = comparisonText(
            delta: data.trendDelta,
            trend: data.trend,
            window: window,
            unit: "%",
            context: .adherence
        )

        return InsightReport(
            category:         .medication,
            title:            "Medication Adherence",
            primaryValue:     pctStr,
            primaryLabel:     primaryLabel,
            trend:            data.trend,
            trendDelta:       data.trendDelta,
            comparisonText:   comparison,
            timeRangeLabel:   windowLabel,
            graphData:        graphData,
            heatmapData:      heatmap,
            secondaryMetrics: secondary,
            summaryText:      summary,
            actionScreen:     .medicationAdherence
        )
    }

    // MARK: - Fluid

    /// Compute fluid intake for the given window.
    func fluidInsight(window: InsightTimeWindow) -> FluidInsightData {
        let today = Date()
        let days  = window.rawValue
        let dates = pastDates(count: days, endingOn: today)
        let prevDates = pastDates(count: days, endingOn: dates.first ?? today)
        let goal  = LimitsManager.shared.getFluidLimit()  // ml

        let daily = dates.map { date -> (date: Date, ml: Int) in
            (date: date, ml: ActivityLogManager.shared.fluidTotal(for: date))
        }

        let prevDaily = prevDates.map { date -> Int in
            ActivityLogManager.shared.fluidTotal(for: date)
        }

        let daysWithData   = daily.filter { $0.ml > 0 }.count
        let totalMl        = daily.reduce(0) { $0 + $1.ml }
        let activeDays     = max(daysWithData, 1)
        let avgDaily       = totalMl / activeDays

        let prevTotal      = prevDaily.reduce(0, +)
        let prevActiveDays = max(prevDaily.filter { $0 > 0 }.count, 1)
        let prevAvg        = prevTotal / prevActiveDays

        let goalPct        = goal > 0 ? Double(avgDaily) / Double(goal) * 100 : 0
        let consistencyDays = daily.filter { goal > 0 && Double($0.ml) / Double(goal) >= 0.8 }.count

        let delta = abs(Double(avgDaily) - Double(prevAvg))
        let pctDelta = prevAvg > 0 ? (delta / Double(prevAvg)) * 100 : 0
        let trend = trendDirection(
            current:  Double(avgDaily),
            previous: Double(prevAvg),
            higherIsBetter: false  // for fluid, less variance from goal is better, but we track actual vs goal
        )

        return FluidInsightData(
            dailyIntake:     daily,
            averageDaily:    avgDaily,
            goalMl:          goal,
            goalPct:         goalPct,
            consistencyDays: consistencyDays,
            trend:           trend,
            trendDelta:      pctDelta,
            previousAvg:     prevAvg,
            actualDays:      dates.count
        )
    }

    func fluidReport(window: InsightTimeWindow) -> InsightReport {
        let data = fluidInsight(window: window)
        let windowLabel = timeRangeLabel(days: data.actualDays, window: window)

        let avgStr = formatMl(data.averageDaily)
        let primaryLabel = "Avg per day"

        let graphValues = data.dailyIntake.map { Double($0.ml) }
        let graphLabels = data.dailyIntake.map { shortDayLabel($0.date) }
        let graphData   = InsightGraphData(
            values:    graphValues,
            labels:    graphLabels,
            goalValue: Double(data.goalMl),
            unit:      "ml"
        )

        let secondary: [SecondaryMetric] = [
            SecondaryMetric(label: "Goal",        value: formatMl(data.goalMl),          iconName: "target"),
            SecondaryMetric(label: "Goal reached", value: "\(data.consistencyDays) days",   iconName: "checkmark.seal"),
            SecondaryMetric(label: "Avg vs goal",  value: String(format: "%.0f%%", data.goalPct), iconName: "percent"),
        ]

        let summary  = buildFluidSummary(data: data, windowLabel: windowLabel)
        let comparison = comparisonText(
            delta: data.trendDelta,
            trend: data.trend,
            window: window,
            unit: "ml",
            context: .fluid
        )

        return InsightReport(
            category:         .fluids,
            title:            "Fluid Intake",
            primaryValue:     avgStr,
            primaryLabel:     primaryLabel,
            trend:            data.trend,
            trendDelta:       data.trendDelta,
            comparisonText:   comparison,
            timeRangeLabel:   windowLabel,
            graphData:        graphData,
            heatmapData:      nil,
            secondaryMetrics: secondary,
            summaryText:      summary,
            actionScreen:     .hydrationStatus
        )
    }

    // MARK: - Nutrients

    func nutrientInsight(window: InsightTimeWindow) -> NutrientInsightData {
        let today = Date()
        let days  = window.rawValue
        let dates = pastDates(count: days, endingOn: today)
        let prevDates = pastDates(count: days, endingOn: dates.first ?? today)

        let daily = dates.map { date -> NutrientInsightData.DailyNutrient in
            let t = ActivityLogManager.shared.nutrientTotals(for: date)
            return NutrientInsightData.DailyNutrient(
                date: date, calories: t.calories,
                potassium: t.potassium, sodium: t.sodium, protein: t.protein
            )
        }
        let prevDaily = prevDates.map { ActivityLogManager.shared.nutrientTotals(for: $0) }

        let daysWithData = daily.filter { $0.calories > 0 }.count
        let active = max(daysWithData, 1)

        let avgCal  = daily.reduce(0) { $0 + $1.calories }  / active
        let avgPot  = daily.reduce(0) { $0 + $1.potassium } / active
        let avgSod  = daily.reduce(0) { $0 + $1.sodium }    / active
        let avgPro  = daily.reduce(0) { $0 + $1.protein }   / active

        let prevActive = max(prevDaily.filter { $0.calories > 0 }.count, 1)
        let prevAvgCal = prevDaily.reduce(0) { $0 + $1.calories } / prevActive

        let calLimit  = LimitsManager.shared.getCalorieLimit()
        let potLimit  = LimitsManager.shared.getPotassiumLimit()
        let sodLimit  = LimitsManager.shared.getSodiumLimit()
        let proLimit  = LimitsManager.shared.getProteinLimit()

        func compliance(values: [Int], limit: Int) -> Double {
            guard !values.isEmpty, limit > 0 else { return 0 }
            let within   = values.filter { $0 <= limit && $0 > 0 }.count
            let nonZero  = max(1, values.filter { $0 > 0 }.count)
            return Double(within) / Double(nonZero) * 100
        }

        let calComp  = compliance(values: daily.map { $0.calories },  limit: calLimit)
        let potComp  = compliance(values: daily.map { $0.potassium }, limit: potLimit)
        let sodComp  = compliance(values: daily.map { $0.sodium },    limit: sodLimit)
        let proComp  = compliance(values: daily.map { $0.protein },   limit: proLimit)

        let delta    = abs(Double(avgCal) - Double(prevAvgCal))
        let pctDelta = prevAvgCal > 0 ? (delta / Double(prevAvgCal)) * 100 : 0
        let trend    = trendDirection(current: Double(avgCal), previous: Double(prevAvgCal), higherIsBetter: false)

        return NutrientInsightData(
            daily:               daily,
            avgCalories:         avgCal,
            avgPotassium:        avgPot,
            avgSodium:           avgSod,
            avgProtein:          avgPro,
            calorieCompliance:   calComp,
            potassiumCompliance: potComp,
            sodiumCompliance:    sodComp,
            proteinCompliance:   proComp,
            trend:               trend,
            trendDelta:          pctDelta,
            actualDays:          dates.count
        )
    }

    func nutrientReport(window: InsightTimeWindow, focus: HealthInsight.InsightCategory = .potassium) -> InsightReport {
        let data        = nutrientInsight(window: window)
        let windowLabel = timeRangeLabel(days: data.actualDays, window: window)

        // Pick primary metric based on focus
        let (primaryValue, primaryLabel, graphValues, unit, compliance, limit, actionScreen): (String, String, [Int], String, Double, Int, HealthInsight.DestinationScreen) = {
            switch focus {
            case .potassium:
                return ("\(data.avgPotassium)mg", "Avg Potassium/day",
                        data.daily.map { $0.potassium }, "mg",
                        data.potassiumCompliance, LimitsManager.shared.getPotassiumLimit(), .nutrientBalance)
            case .sodium:
                return ("\(data.avgSodium)mg", "Avg Sodium/day",
                        data.daily.map { $0.sodium }, "mg",
                        data.sodiumCompliance, LimitsManager.shared.getSodiumLimit(), .nutrientBalance)
            case .protein:
                return ("\(data.avgProtein)g", "Avg Protein/day",
                        data.daily.map { $0.protein }, "g",
                        data.proteinCompliance, LimitsManager.shared.getProteinLimit(), .nutrientBalance)
            default:
                return ("\(data.avgCalories) kcal", "Avg Calories/day",
                        data.daily.map { $0.calories }, "kcal",
                        data.calorieCompliance, LimitsManager.shared.getCalorieLimit(), .nutrientBalance)
            }
        }()

        let graphLabels = data.daily.map { shortDayLabel($0.date) }
        let graphDataObj = InsightGraphData(
            values:    graphValues.map { Double($0) },
            labels:    graphLabels,
            goalValue: Double(limit),
            unit:      unit
        )

        let secondary: [SecondaryMetric] = [
            SecondaryMetric(label: "Days within limit", value: String(format: "%.0f%%", compliance), iconName: "checkmark.seal"),
            SecondaryMetric(label: "Avg Calories",      value: "\(data.avgCalories) kcal",           iconName: "flame"),
            SecondaryMetric(label: "Avg Protein",       value: "\(data.avgProtein)g",                iconName: "p.circle"),
        ]

        let summary    = buildNutrientSummary(data: data, focus: focus, windowLabel: windowLabel)
        let comparison = comparisonText(
            delta: data.trendDelta,
            trend: data.trend,
            window: window,
            unit: unit,
            context: .nutrient
        )

        return InsightReport(
            category:         focus,
            title:            categoryTitle(focus),
            primaryValue:     primaryValue,
            primaryLabel:     primaryLabel,
            trend:            data.trend,
            trendDelta:       data.trendDelta,
            comparisonText:   comparison,
            timeRangeLabel:   windowLabel,
            graphData:        graphDataObj,
            heatmapData:      nil,
            secondaryMetrics: secondary,
            summaryText:      summary,
            actionScreen:     actionScreen
        )
    }

    // MARK: - Insight Card Generation (for home highlights)

    /// Returns top 3 InsightReports ordered by urgency for the home screen highlights.
    func generateHomeInsightReports() -> [InsightReport] {
        let med    = medicationReport(window: .week)
        let fluid  = fluidReport(window: .week)
        let potassium = nutrientReport(window: .week, focus: .potassium)

        var reports = [med, fluid, potassium]

        // Sort: critical issues first (missed meds, exceeded limits), then declining trends, then positive
        reports.sort { a, b in
            let scoreA = urgencyScore(a)
            let scoreB = urgencyScore(b)
            return scoreA > scoreB
        }

        return Array(reports.prefix(3))
    }

    // MARK: - Private Helpers

    private enum Context { case adherence, fluid, nutrient }

    private func comparisonText(delta: Double, trend: InsightTrend, window: InsightTimeWindow, unit: String, context: Context) -> String {
        guard delta > 0 else { return "No change from last \(window.displayName)" }

        let deltaStr = String(format: "%.0f%%", delta)
        let direction: String
        switch (trend, context) {
        case (.improved, _):   direction = "higher"
        case (.decreased, _):  direction = "lower"
        case (.unchanged, _):  return "About the same as last \(window.displayName)"
        }

        return "\(deltaStr) \(direction) than last \(window.displayName)"
    }

    private func buildMedicationSummary(data: MedicationInsightData, windowLabel: String) -> String {
        let pct = String(format: "%.0f%%", data.adherencePct)
        return "\(pct) adherence \(windowLabel.lowercased())\n\(data.missedDoses) doses missed out of \(data.totalDoses) scheduled"
    }

    private func buildFluidSummary(data: FluidInsightData, windowLabel: String) -> String {
        let avgStr = formatMl(data.averageDaily)
        let goalStr = formatMl(data.goalMl)
        return "\(avgStr)/day average \(windowLabel.lowercased())\nTarget met on \(data.consistencyDays) of \(data.actualDays) days"
    }

    private func buildNutrientSummary(data: NutrientInsightData, focus: HealthInsight.InsightCategory, windowLabel: String) -> String {
        switch focus {
        case .potassium:
            return "\(data.avgPotassium) mg potassium/day average\nWithin limit on \(String(format: "%.0f%%", data.potassiumCompliance)) of days"
        case .sodium:
            return "\(data.avgSodium) mg sodium/day average\nWithin limit on \(String(format: "%.0f%%", data.sodiumCompliance)) of days"
        case .protein:
            return "\(data.avgProtein) g protein/day average\nTarget reached on \(String(format: "%.0f%%", data.proteinCompliance)) of days"
        default:
            return "\(data.avgCalories) kcal/day average\nNutrition logged on \(data.daily.filter { $0.calories > 0 }.count) days"
        }
    }

    private func buildHeatmap(from intensities: [(Date, Double)]) -> InsightHeatmapData? {
        guard !intensities.isEmpty else { return nil }
        let cells = intensities.map { (date, intensity) -> InsightHeatmapData.Cell in
            let day = cal.component(.day, from: date)
            return InsightHeatmapData.Cell(
                date:  date,
                value: intensity,
                label: "\(day)"
            )
        }
        return InsightHeatmapData(
            cells:     cells,
            startDate: intensities.first!.0,
            endDate:   intensities.last!.0
        )
    }

    func pastDates(count: Int, endingOn end: Date) -> [Date] {
        let startOfEnd = cal.startOfDay(for: end)
        return (0..<count).compactMap { offset in
            cal.date(byAdding: .day, value: -(count - 1 - offset), to: startOfEnd)
        }
    }

    private func trendDirection(current: Double, previous: Double, higherIsBetter: Bool) -> InsightTrend {
        guard previous > 0 else { return .unchanged }
        let change = ((current - previous) / previous) * 100
        if abs(change) < 5 { return .unchanged }
        let isHigher = change > 0
        if higherIsBetter { return isHigher ? .improved : .decreased }
        else               { return isHigher ? .decreased : .improved }
    }

    private func timeRangeLabel(days: Int, window: InsightTimeWindow) -> String {
        switch days {
        case 1:        return "Today"
        case 7:        return "Past 7 days"
        case 30:       return "Past 30 days"
        case 31...179: return "Past \(days) days"
        case 180:      return "Past 6 months"
        case 365:      return "Past year"
        default:       return "Past \(days) days"
        }
    }

    private func shortDayLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return String(df.string(from: date).prefix(3))
    }

    private func formatMl(_ ml: Int) -> String {
        if ml >= 1000 {
            let l = Double(ml) / 1000.0
            return String(format: "%.1f L", l)
        }
        return "\(ml) ml"
    }

    private func categoryTitle(_ cat: HealthInsight.InsightCategory) -> String {
        switch cat {
        case .potassium:  return "Potassium"
        case .sodium:     return "Sodium"
        case .protein:    return "Protein"
        case .fluids:     return "Fluid Intake"
        case .medication: return "Medication Adherence"
        case .weight:     return "Weight"
        case .general:    return "General"
        }
    }

    private func urgencyScore(_ report: InsightReport) -> Int {
        var score = 0
        if report.category == .medication && report.trend == .decreased { score += 40 }
        if report.trend == .decreased { score += 20 }
        if report.trendDelta > 15 { score += 10 }
        if report.trend == .improved { score -= 5 }
        return score
    }
}

