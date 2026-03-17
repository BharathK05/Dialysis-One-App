//
//  ClinicalSummaryEngine.swift
//  Dialysis One App
//
//  Created by user@22 on 05/02/26.
//


import Foundation
import NaturalLanguage

final class ClinicalSummaryEngine {

    static func generateBullets(from text: String, maxBullets: Int = 3) -> [String] {

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var candidates: [String] = []

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).lowercased()

            // Apple-style filtering (no regex hacks)
            if isClinicallyRelevant(sentence) {
                candidates.append(sentence)
            }
            return true
        }

        let ranked = rankSentences(candidates)
        let selected = ranked.prefix(maxBullets)

        // 🔑 Controlled rewriting (this is the key)
        return selected.map { rewriteToUserBullet($0) }
    }

    // MARK: - Apple-style relevance check
    private static func isClinicallyRelevant(_ sentence: String) -> Bool {
        let keywords = [
            "potassium", "sodium", "chloride",
            "creatinine", "bun", "egfr",
            "high", "low", "normal", "elevated"
        ]
        return keywords.contains { sentence.contains($0) }
    }

    // MARK: - Ranking
    private static func rankSentences(_ sentences: [String]) -> [String] {
        sentences.sorted { $0.count < $1.count }
    }

    // MARK: - Rewrite (UX layer)
    private static func rewriteToUserBullet(_ sentence: String) -> String {

        if sentence.contains("bun") && sentence.contains("creatinine") {
            return "• Kidney-related markers (BUN and creatinine) were assessed in this report."
        }

        if sentence.contains("egfr") {
            return "• Estimated kidney filtration (eGFR) was calculated to assess kidney function."
        }

        if sentence.contains("potassium") {
            return "• Potassium levels were reviewed for electrolyte balance."
        }

        return "• Key laboratory values were reviewed as part of this report."
    }
}

