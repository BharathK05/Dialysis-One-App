//
//  InsightEngine.swift
//  Dialysis One App
//
//  Created by user@22 on 04/02/26.
//


import Foundation

final class InsightEngine {

    static func generateInsights(
        from report: BloodReport,
        previousReports: [BloodReport]
    ) -> [ReportInsight] {

        guard
            let text = report.extractedText,
            !text.isEmpty
        else {
            return [
                ReportInsight(
                    title: "Limited data detected",
                    message: "This report appears to be scanned or partially unreadable. Some values may not be available.",
                    tone: .neutral,
                    reportDate: report.date
                )
            ]
        }

        let metrics = ReportMetricExtractor.extract(from: text)
        guard !metrics.isEmpty else {
            return [
                ReportInsight(
                    title: "No key values found",
                    message: "We could not identify common blood test values in this report.",
                    tone: .neutral,
                    reportDate: report.date
                )
            ]
        }

        var insights: [ReportInsight] = []

        for metric in metrics {

            let status = DialysisRulesEngine.evaluate(metric: metric)

            let message: String
            let tone: InsightTone

            switch status {
            case .normal:
                message = "\(metric.name) is within the usual range in this report."
                tone = .reassuring

            case .high:
                message = "\(metric.name) is slightly above the usual range in this report."
                tone = .attention

            case .critical:
                message = "\(metric.name) is significantly above the usual range in this report."
                tone = .attention
            }

            insights.append(
                ReportInsight(
                    title: metric.name,
                    message: message,
                    tone: tone,
                    reportDate: report.date
                )
            )
        }

        return insights
    }
}
