//
//  MealNamingService.swift
//  Dialysis One App
//
//  Created by user@1 on 27/12/25.
//

import Foundation

final class MealNamingService {

    static let shared = MealNamingService()
    private init() {}

    private let apiKey = Secrets.GEMINI_API_KEY
    private let model = "gemini-2.5-flash"

    func nameMeal(from foods: [DetectedFood]) async -> String? {

        let components = foods.map { food in
            let r = role(for: food)
            return "\(food.name) (\(r))"
        }

        let prompt = """
        These food items appear together in an Indian meal:

        \(components.joined(separator: ", "))

        Question:
        What is the common Indian name for this meal?

        Rules:
        - Respond with a COMPLETE meal name
        - Use 2 to 5 words
        - Do not cut the response
        - Do not explain
        """


        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 40
            ]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: body),
              let url = URL(string:
                "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
              ) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        do {
            let (resp, _) = try await URLSession.shared.data(for: request)
            let text = extractText(from: resp)
            return text
        } catch {
            return nil
        }
    }

    private func extractText(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]] else {
            print("❌ Gemini response not JSON")
            return nil
        }

        for candidate in candidates {
            if let content = candidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]] {

                for part in parts {
                    if let text = part["text"] as? String {
                        let cleaned = text
                            .replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        if cleaned.split(separator: " ").count >= 2 {
                            print("🧠 Gemini meal name:", cleaned)
                            return cleaned
                        }
                    }
                }
            }
        }

        print("❌ Gemini meal-name parse failed (safe)")
        return nil
    }

}
