//
//  InsightEngine.swift
//  Dialysis One App
//
//  Smart Highlights System - Insight Generation Logic
//  IMPROVED: Always shows at least one insight, better empty state handling
//

import Foundation

class HighlightsInsightEngine {
    static let shared = HighlightsInsightEngine()
    
    private init() {}
    
    private var uid: String {
        return FirebaseAuthManager.shared.getUserID() ?? "guest"
    }
    
    private let history = InsightHistoryManager.shared
    
    // MARK: - Main API
    
    /// Generate today's insights based on user data
    /// Returns max 3 insights, prioritized by safety and relevance
    /// IMPROVED: Always returns at least 1 insight
    func generateInsights() -> [HealthInsight] {
        var allInsights: [HealthInsight] = []
        
        // Gather all potential insights
        allInsights += checkPotassiumInsights()
        allInsights += checkSodiumInsights()
        allInsights += checkFluidInsights()
        allInsights += checkMedicationInsights()
        allInsights += checkWeightInsights()
        
        // If no alerts, add positive/general insights
        if allInsights.isEmpty || !allInsights.contains(where: { $0.priority == .critical }) {
            allInsights += checkPositiveInsights()
        }
        
        // Filter out recently shown insights (prevent repetition)
        // BUT: Always keep at least one insight
        let filtered = allInsights.filter { insight in
            let identifier = generateIdentifier(for: insight)
            return !history.wasShownRecently(identifier, withinDays: 1)
        }
        
        // If filtering removed everything, use unfiltered list
        allInsights = filtered.isEmpty ? allInsights : filtered
        
        // Sort by priority (critical first)
        allInsights.sort { $0.priority < $1.priority }
        
        // Take top 3
        let selectedInsights = Array(allInsights.prefix(3))
        
        // Record that we showed these
        selectedInsights.forEach { insight in
            let identifier = generateIdentifier(for: insight)
            history.recordShown(identifier)
        }
        
        // SAFETY: If still empty, return a default welcome message
        if selectedInsights.isEmpty {
            return [createWelcomeInsight()]
        }
        
        return selectedInsights
    }
    
    // MARK: - Potassium Insights
    
    private func checkPotassiumInsights() -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        let consumed = ActivityLogManager.shared.todayNutrientTotals().potassium
        let goal = LimitsManager.shared.getPotassiumLimit()
        
        let percentage = Double(consumed) / Double(goal) * 100
        
        // 🔴 CRITICAL: Exceeded limit
        if percentage > 100 {
            insights.append(HealthInsight(
                type: .warning,
                category: .potassium,
                title: "Potassium",
                message: "You exceeded your potassium limit today.",
                detail: "\(consumed)mg consumed out of \(goal)mg limit.",
                priority: .critical,
                actionScreen: .nutrientBalance
            ))
        }
        // 🟠 WARNING: Close to limit (80-100%)
        else if percentage >= 80 {
            insights.append(HealthInsight(
                type: .warning,
                category: .potassium,
                title: "Potassium",
                message: "You're close to your potassium limit.",
                detail: "\(consumed)mg of \(goal)mg consumed.",
                priority: .high,
                actionScreen: .nutrientBalance
            ))
        }
        
        // 📈 TREND: Check 3-day increasing pattern
        if let trend = checkNutrientTrend(nutrient: "potassium", days: 3) {
            if trend.trendDirection == .increasing {
                insights.append(HealthInsight(
                    type: .trend,
                    category: .potassium,
                    title: "Potassium Trend",
                    message: "Your potassium intake has increased 3 days in a row.",
                    detail: "Consider monitoring high-potassium foods.",
                    priority: .medium,
                    actionScreen: .nutrientBalance,
                    trendData: trend
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Sodium Insights
    
    private func checkSodiumInsights() -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        let consumed = ActivityLogManager.shared.todayNutrientTotals().sodium
        let goal = LimitsManager.shared.getSodiumLimit()
        
        let percentage = Double(consumed) / Double(goal) * 100
        
        // 🔴 CRITICAL: Exceeded limit
        if percentage > 100 {
            insights.append(HealthInsight(
                type: .warning,
                category: .sodium,
                title: "Sodium",
                message: "You exceeded your sodium limit today.",
                detail: "\(consumed)mg consumed out of \(goal)mg limit.",
                priority: .critical,
                actionScreen: .nutrientBalance
            ))
        }
        // 🟠 WARNING: Close to limit
        else if percentage >= 80 {
            insights.append(HealthInsight(
                type: .warning,
                category: .sodium,
                title: "Sodium",
                message: "You're close to your sodium limit.",
                detail: "\(consumed)mg of \(goal)mg consumed.",
                priority: .high,
                actionScreen: .nutrientBalance
            ))
        }
        
        // 📈 TREND: 3-day increase
        if let trend = checkNutrientTrend(nutrient: "sodium", days: 3) {
            if trend.trendDirection == .increasing {
                insights.append(HealthInsight(
                    type: .trend,
                    category: .sodium,
                    title: "Sodium Trend",
                    message: "Your sodium intake has increased 3 days in a row.",
                    detail: "Watch processed foods and salt usage.",
                    priority: .medium,
                    actionScreen: .nutrientBalance,
                    trendData: trend
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Fluid Insights
    
    private func checkFluidInsights() -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        let consumed = ActivityLogManager.shared.todayFluidTotal()
        let goal = LimitsManager.shared.getFluidLimit()
        
        let percentage = Double(consumed) / Double(goal) * 100
        
        // 🔴 CRITICAL: Exceeded fluid goal
        if percentage > 100 {
            insights.append(HealthInsight(
                type: .warning,
                category: .fluids,
                title: "Fluid Intake",
                message: "You exceeded your fluid goal today.",
                detail: "\(consumed)ml of \(goal)ml consumed.",
                priority: .critical,
                actionScreen: .hydrationStatus
            ))
        }
        
        // 🟢 POSITIVE: Streak of staying within limit
        if let streak = checkFluidStreak() {
            if streak >= 5 {
                insights.append(HealthInsight(
                    type: .positive,
                    category: .fluids,
                    title: "Hydration Control",
                    message: "You've stayed within your fluid goal for \(streak) days.",
                    detail: "Great job managing your hydration!",
                    priority: .low,
                    actionScreen: .hydrationStatus
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Medication Insights
    
    private func checkMedicationInsights() -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        let adherence = MedicationStore.shared.getTodayAdherencePercentage()
        let missedCount = MedicationStore.shared.getMissedMedicationsCount()
        
        // 🔴 CRITICAL: Missed medications today
        if missedCount > 0 {
            insights.append(HealthInsight(
                type: .warning,
                category: .medication,
                title: "Medications",
                message: "You have \(missedCount) missed medication\(missedCount > 1 ? "s" : "").",
                detail: "Take them as soon as possible.",
                priority: .critical,
                actionScreen: .medicationAdherence
            ))
        }
        // 🟢 POSITIVE: Perfect adherence
        else if adherence >= 100 {
            insights.append(HealthInsight(
                type: .positive,
                category: .medication,
                title: "Medications",
                message: "Perfect medication adherence today!",
                detail: "All medications taken on time.",
                priority: .low,
                actionScreen: .medicationAdherence
            ))
        }
        
        // 🟠 WARNING: Weekly adherence declining
        let weeklyAdherence = MedicationStore.shared.getWeeklyAdherencePercentage()
        if weeklyAdherence < 80 {
            insights.append(HealthInsight(
                type: .warning,
                category: .medication,
                title: "Medication Adherence",
                message: "Your medication adherence decreased this week.",
                detail: "\(Int(weeklyAdherence))% adherence over the past 7 days.",
                priority: .high,
                actionScreen: .medicationAdherence
            ))
        }
        
        return insights
    }
    
    // MARK: - Weight Insights
    
    private func checkWeightInsights() -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Get recent weight entries
        let recentWeights = getRecentWeights(days: 3)
        
        if recentWeights.count >= 2 {
            let latest = recentWeights[0]
            let previous = recentWeights[1]
            let change = latest - previous
            
            // 🔴 CRITICAL: Sudden weight gain (>2kg)
            if change >= 2.0 {
                insights.append(HealthInsight(
                    type: .warning,
                    category: .weight,
                    title: "Weight Change",
                    message: "Your weight increased significantly.",
                    detail: "Gained \(String(format: "%.1f", change))kg. Possible fluid retention.",
                    priority: .critical,
                    actionScreen: .healthAndVitals
                ))
            }
            // 🟢 POSITIVE: Stable weight
            else if abs(change) < 0.5 {
                insights.append(HealthInsight(
                    type: .positive,
                    category: .weight,
                    title: "Weight",
                    message: "Your weight remains stable.",
                    detail: "Good consistency over the past few days.",
                    priority: .low,
                    actionScreen: .healthAndVitals
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Positive Insights (Fallbacks)
    
    private func checkPositiveInsights() -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        let totals = ActivityLogManager.shared.todayNutrientTotals()
        let potassiumConsumed = totals.potassium
        let potassiumGoal = LimitsManager.shared.getPotassiumLimit()
        let sodiumConsumed = totals.sodium
        let sodiumGoal = LimitsManager.shared.getSodiumLimit()
        let proteinConsumed = totals.protein
        let proteinGoal = LimitsManager.shared.getProteinLimit()
        
        let potassiumPct = Double(potassiumConsumed) / Double(potassiumGoal) * 100
        let sodiumPct = Double(sodiumConsumed) / Double(sodiumGoal) * 100
        let proteinPct = Double(proteinConsumed) / Double(proteinGoal) * 100
        
        // Check if user has logged ANY data today
        let hasLoggedData = potassiumConsumed > 0 || sodiumConsumed > 0 || proteinConsumed > 0
        
        // 🟢 Perfect balance day (all nutrients 70-100%)
        if hasLoggedData &&
           potassiumPct >= 70 && potassiumPct <= 100 &&
           sodiumPct >= 70 && sodiumPct <= 100 &&
           proteinPct >= 70 && proteinPct <= 100 {
            insights.append(HealthInsight(
                type: .positive,
                category: .general,
                title: "Balanced Nutrition",
                message: "Great job maintaining balanced nutrition today.",
                detail: "All nutrients within healthy range.",
                priority: .low,
                actionScreen: .nutrientBalance
            ))
        }
        // 🟢 User has started logging
        else if hasLoggedData {
            insights.append(HealthInsight(
                type: .informational,
                category: .general,
                title: "Daily Progress",
                message: "You're tracking your nutrition today.",
                detail: "Keep logging meals to get personalized insights.",
                priority: .low,
                actionScreen: .nutrientBalance
            ))
        }
        // 🟢 No data yet - welcome message
        else {
            insights.append(createWelcomeInsight())
        }
        
        return insights
    }
    
    /// Create a welcome insight for first-time or empty state
    private func createWelcomeInsight() -> HealthInsight {
        return HealthInsight(
            type: .informational,
            category: .general,
            title: "Welcome to Highlights",
            message: "Start tracking your day to see personalized insights.",
            detail: "Log meals, fluids, and medications to get helpful health tips.",
            priority: .low,
            actionScreen: nil
        )
    }
    
    // MARK: - Helper Functions
    
    private func generateIdentifier(for insight: HealthInsight) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let categoryString = String(describing: insight.category)
        let typeString = String(describing: insight.type)
        
        return "\(categoryString)_\(typeString)_\(dateString)"
    }
    
    /// Check nutrient trend over past N days
    private func checkNutrientTrend(nutrient: String, days: Int) -> HealthInsight.TrendData? {
        // This would ideally fetch historical data
        // For now, return nil as we'd need to implement historical storage
        // TODO: Implement with actual historical data tracking
        return nil
    }
    
    /// Check fluid control streak
    private func checkFluidStreak() -> Int? {
        // Would check historical data for consecutive days within limit
        // TODO: Implement with actual historical tracking
        return nil
    }
    
    /// Get recent weight entries
    private func getRecentWeights(days: Int) -> [Double] {
        // Would fetch from HealthKit or stored weight logs
        // TODO: Implement with actual weight tracking
        return []
    }
}

// MARK: - MedicationStore Extension for Insights

extension MedicationStore {
    
    /// Get count of medications that were scheduled for today but not taken
    func getMissedMedicationsCount() -> Int {
        let today = Date()
        let currentTimeOfDay = TimeOfDay.current(for: today)
        
        // Get all medications for current time of day
        let currentMeds = medicationsFor(timeOfDay: currentTimeOfDay, date: today)
        
        // Count how many are NOT taken
        let missedCount = currentMeds.filter { medication in
            !medication.isTaken(on: today, timeOfDay: currentTimeOfDay)
        }.count
        
        return missedCount
    }
    
    /// Get today's adherence percentage (0-100)
    func getTodayAdherencePercentage() -> Double {
        let today = Date()
        let allTimesOfDay = TimeOfDay.allCases
        
        var totalMedications = 0
        var totalTaken = 0
        
        for timeOfDay in allTimesOfDay {
            let meds = medicationsFor(timeOfDay: timeOfDay, date: today)
            totalMedications += meds.count
            
            let taken = meds.filter { medication in
                medication.isTaken(on: today, timeOfDay: timeOfDay)
            }.count
            
            totalTaken += taken
        }
        
        guard totalMedications > 0 else { return 100.0 }
        
        return (Double(totalTaken) / Double(totalMedications)) * 100
    }
    
    /// Get weekly adherence percentage (0-100)
    func getWeeklyAdherencePercentage() -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            return getTodayAdherencePercentage()
        }
        
        var totalMedications = 0
        var totalTaken = 0
        
        // Iterate through each day in the week
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // Check all times of day for this date
            for timeOfDay in TimeOfDay.allCases {
                let meds = medicationsFor(timeOfDay: timeOfDay, date: date)
                totalMedications += meds.count
                
                let taken = meds.filter { medication in
                    medication.isTaken(on: date, timeOfDay: timeOfDay)
                }.count
                
                totalTaken += taken
            }
        }
        
        guard totalMedications > 0 else { return 100.0 }
        
        return (Double(totalTaken) / Double(totalMedications)) * 100
    }
}
