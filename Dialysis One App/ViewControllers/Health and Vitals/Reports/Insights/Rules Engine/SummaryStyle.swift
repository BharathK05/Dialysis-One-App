//
//  SummaryStyle.swift
//  Dialysis One App
//
//  Created by user@22 on 05/02/26.
//


import Foundation

enum SummaryStyle {
    case clinicalNeutral
}

final class SummaryEngine {

    static func generate(
        from text: String,
        style: SummaryStyle = .clinicalNeutral
    ) -> String {

        // 🚧 Phase 4 — Stub (safe & deterministic)
        // Replace this later with Apple Foundation Models

        return """
        This report shows mostly stable electrolyte levels. Potassium is mildly elevated, while sodium and chloride remain within the usual range. No immediate abnormalities are evident based on the extracted values.
        """
    }
}
