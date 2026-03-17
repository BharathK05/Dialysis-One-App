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
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return [
                ReportInsight(
                    section: .summary,
                    title: "Summary",
                    message: "This report appears to be scanned or unreadable. Some information may not be available.",
                    tone: .neutral,
                    reportDate: report.date
                )
            ]
        }

        let metrics = ReportMetricExtractor.extract(from: text)

        // ✅ CASE 1: Structured lab values found
        if !metrics.isEmpty {

            var results: [ReportInsight] = []

            // Summary FIRST
            let bullets = ClinicalSummaryEngine.generateBullets(from: text)
            let summaryMessage = bullets.joined(separator: "\n")

            results.append(
                ReportInsight(
                    section: .summary,
                    title: "Summary",
                    message: summaryMessage,
                    tone: .neutral,
                    reportDate: report.date
                )
            )

            // Vital insights
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

                results.append(
                    ReportInsight(
                        section: .vital,
                        title: metric.name,
                        message: message,
                        tone: tone,
                        reportDate: report.date
                    )
                )
            }

            return results
        }

        // ✅ CASE 2: Narrative / discharge summary
        if looksLikeNarrativeText(text) {
            return [
                ReportInsight(
                    section: .summary,
                    title: "Summary",
                    message: "This report contains descriptive clinical information rather than structured lab values.",
                    tone: .neutral,
                    reportDate: report.date
                )
            ]
        }

        // ✅ CASE 3: Nothing usable
        return [
            ReportInsight(
                section: .summary,
                title: "Summary",
                message: "We could not identify key clinical values in this report.",
                tone: .neutral,
                reportDate: report.date
            )
        ]
    }


    private static func looksLikeNarrativeText(_ text: String) -> Bool {
        let wordCount = text.split { $0.isWhitespace || $0.isNewline }.count
        return wordCount > 40
    }
}
