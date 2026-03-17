import Foundation
import NaturalLanguage

final class ClinicalSummaryEngine {

    static func generateSummary(from text: String, maxSentences: Int = 3) -> String {

        // 1️⃣ Break text into sentences
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if sentence.count > 20 {
                sentences.append(sentence)
            }
            return true
        }

        guard !sentences.isEmpty else {
            return "No clinically relevant summary could be generated from this report."
        }

        // 2️⃣ Rank sentences by clinical relevance
        let ranked = rankSentences(sentences)

        // 3️⃣ Pick top N
        let selected = ranked.prefix(maxSentences)

        return selected.joined(separator: " ")
    }

    // MARK: - Sentence ranking
    private static func rankSentences(_ sentences: [String]) -> [String] {

        let keywords = [
            "potassium", "sodium", "chloride", "creatinine",
            "elevated", "normal", "high", "low",
            "dialysis", "renal", "electrolyte"
        ]

        return sentences.sorted { a, b in
            score(a, keywords) > score(b, keywords)
        }
    }

    private static func score(_ sentence: String, _ keywords: [String]) -> Int {
        let lower = sentence.lowercased()
        return keywords.reduce(0) { acc, key in
            acc + (lower.contains(key) ? 2 : 0)
        } + sentence.count / 40
    }
}
