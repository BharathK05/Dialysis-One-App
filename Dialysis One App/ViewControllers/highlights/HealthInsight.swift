//
//  HealthInsight.swift
//  Dialysis One App
//
//  Smart Highlights System - Data Models
//  FIXED VERSION - Addresses compilation errors
//

import UIKit

// MARK: - Health Insight Model

struct HealthInsight {
    let id: UUID
    let type: InsightType
    let category: InsightCategory
    let title: String
    let message: String
    let detail: String?
    let priority: InsightPriority
    let actionScreen: DestinationScreen?
    let timestamp: Date
    let trendData: TrendData?
    
    enum InsightType {
        case warning        // Red/Orange - needs attention
        case positive       // Green - encouraging
        case informational  // Blue/Purple - FYI
        case trend          // Graph icon - pattern detected
    }
    
    enum InsightCategory {
        case potassium
        case sodium
        case protein
        case fluids
        case medication
        case weight
        case general
        
        var icon: String {
            switch self {
            case .potassium: return "leaf.fill"
            case .sodium: return "circle.hexagongrid.fill"
            case .protein: return "p.circle.fill"
            case .fluids: return "drop.fill"
            case .medication: return "pills.fill"
            case .weight: return "scalemass.fill"
            case .general: return "sparkles"
            }
        }
        
        var color: UIColor {
            switch self {
            case .potassium: return UIColor(red: 0.4, green: 0.8, blue: 0.5, alpha: 1.0) // Soft green
            case .sodium: return UIColor(red: 1.0, green: 0.7, blue: 0.4, alpha: 1.0)    // Soft orange
            case .fluids: return UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)    // Blue
            case .medication: return UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1.0) // Purple
            case .protein: return UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)   // Teal
            case .weight: return UIColor(red: 1.0, green: 0.6, blue: 0.6, alpha: 1.0)    // Soft red
            case .general: return UIColor(red: 0.6, green: 0.6, blue: 0.8, alpha: 1.0)   // Soft purple
            }
        }
    }
    
    enum InsightPriority: Int, Comparable {
        case critical = 0   // Safety alerts (exceeded limits, missed meds)
        case high = 1       // Trend warnings
        case medium = 2     // Informational
        case low = 3        // Positive reinforcement
        
        static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    enum DestinationScreen {
        case nutrientBalance
        case hydrationStatus
        case medicationAdherence
        case healthAndVitals
    }
    
    // FIX: Added missing properties to TrendData
    struct TrendData {
        let values: [Double]
        let labels: [String]
        let trendDirection: TrendDirection
        
        enum TrendDirection {
            case increasing
            case decreasing
            case stable
        }
        
        // FIX: Add computed property for backward compatibility
        var isIncreasing: Bool {
            return trendDirection == .increasing
        }
        
        var isDecreasing: Bool {
            return trendDirection == .decreasing
        }
        
        var isStable: Bool {
            return trendDirection == .stable
        }
    }
    
    init(
        type: InsightType,
        category: InsightCategory,
        title: String,
        message: String,
        detail: String? = nil,
        priority: InsightPriority,
        actionScreen: DestinationScreen? = nil,
        trendData: TrendData? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.category = category
        self.title = title
        self.message = message
        self.detail = detail
        self.priority = priority
        self.actionScreen = actionScreen
        self.timestamp = Date()
        self.trendData = trendData
    }
}

// MARK: - Insight History Manager

class InsightHistoryManager {
    static let shared = InsightHistoryManager()
    
    private let historyKey = "insight_history"
    private let maxHistoryDays = 7
    
    private init() {}
    
    private var uid: String {
        return FirebaseAuthManager.shared.getUserID() ?? "guest"
    }
    
    struct InsightRecord: Codable {
        let insightIdentifier: String  // e.g., "potassium_exceeded_2024-02-06"
        let timestamp: Date
    }
    
    /// Check if an insight was shown recently (prevent duplicates)
    func wasShownRecently(_ identifier: String, withinDays days: Int = 1) -> Bool {
        let history = getHistory()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return history.contains { record in
            record.insightIdentifier == identifier && record.timestamp >= cutoffDate
        }
    }
    
    /// Record that an insight was shown
    func recordShown(_ identifier: String) {
        var history = getHistory()
        history.append(InsightRecord(insightIdentifier: identifier, timestamp: Date()))
        
        // Keep only recent records
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxHistoryDays, to: Date()) ?? Date()
        history = history.filter { $0.timestamp >= cutoffDate }
        
        saveHistory(history)
    }
    
    private func getHistory() -> [InsightRecord] {
        // FIX: Use proper UserDataManager key method if available
        let key = "\(historyKey)_\(uid)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([InsightRecord].self, from: data) else {
            return []
        }
        return records
    }
    
    private func saveHistory(_ records: [InsightRecord]) {
        // FIX: Use proper UserDataManager key method if available
        let key = "\(historyKey)_\(uid)"
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    /// Clear all history (useful for testing)
    func clearHistory() {
        let key = "\(historyKey)_\(uid)"
        UserDefaults.standard.removeObject(forKey: key)
    }
}
