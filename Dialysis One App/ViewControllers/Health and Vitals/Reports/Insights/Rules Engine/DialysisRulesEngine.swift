//
//  DialysisRulesEngine.swift
//  Dialysis One App
//
//  Created by user@22 on 31/01/26.
//


import Foundation

// MARK: - Metric Status (NO medical advice words)
enum MetricStatus: String {
    case normal
    case high
    case critical
}

// MARK: - Rule Definition
struct MetricRule {
    let normalUpper: Double
    let criticalUpper: Double
}

// MARK: - Static Rules Engine (NO AI)
final class DialysisRulesEngine {

    // Values aligned with commonly used dialysis thresholds in India
    static let rules: [String: MetricRule] = [
        "Potassium": MetricRule(normalUpper: 5.5, criticalUpper: 6.0),
        "Sodium": MetricRule(normalUpper: 145, criticalUpper: 150),
        "Creatinine": MetricRule(normalUpper: 1.2, criticalUpper: 5.0),
        "Urea": MetricRule(normalUpper: 40, criticalUpper: 100),
        "Uric Acid": MetricRule(normalUpper: 7.0, criticalUpper: 9.0)
    ]

    static func evaluate(metric: ReportMetric) -> MetricStatus {
        guard let rule = rules[metric.name] else {
            return .normal
        }

        if metric.value > rule.criticalUpper {
            return .critical
        }

        if metric.value > rule.normalUpper {
            return .high
        }

        return .normal
    }
}
