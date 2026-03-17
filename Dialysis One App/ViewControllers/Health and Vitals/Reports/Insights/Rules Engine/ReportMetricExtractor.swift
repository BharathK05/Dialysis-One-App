//
//  ReportMetricExtractor.swift
//  Dialysis One App
//
//  Created by user@22 on 31/01/26.
//

import Foundation


final class ReportMetricExtractor {

    static func extract(from text: String) -> [ReportMetric] {

        let patterns: [(name: String, regex: String, unit: String)] = [
            ("Creatinine", #"Creatinine[:\s]*([\d.]+)\s*mg\s*\/?\s*dL"#, "mg/dL"),
            ("Urea", #"Urea[:\s]*([\d.]+)\s*mg\s*\/?\s*dL"#, "mg/dL"),
            ("Potassium", #"Potassium[:\s]*([\d.]+)\s*mEq\s*\/?\s*L"#, "mEq/L"),
            ("Sodium", #"Sodium[:\s]*([\d.]+)\s*mEq\s*\/?\s*L"#, "mEq/L"),
            ("Chloride", #"Chloride[:\s]*([\d.]+)\s*mEq\s*\/?\s*L"#, "mEq/L"),
            ("Uric Acid", #"Uric\s*Acid[:\s]*([\d.]+)\s*mg\s*\/?\s*dL"#, "mg/dL")
        ]

        var results: [ReportMetric] = []

        for p in patterns {
            guard let regex = try? NSRegularExpression(pattern: p.regex, options: .caseInsensitive) else { continue }

            let range = NSRange(text.startIndex..., in: text)

            if let match = regex.firstMatch(in: text, range: range),
               let valueRange = Range(match.range(at: 1), in: text),
               let value = Double(text[valueRange]) {

                results.append(
                    ReportMetric(
                        name: p.name,
                        value: value,
                        unit: p.unit,
                        referenceRange: nil // IMPORTANT: still nil
                    )
                )
            }
        }

        return results
    }
}
