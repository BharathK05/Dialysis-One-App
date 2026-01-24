//
//  FoodPortionClassifier.swift
//  Dialysis One App
//

import Foundation

// MARK: - Models

enum PortionType: String, Codable {
    case weight = "WEIGHT"
    case count  = "COUNT"
    case meal   = "MEAL"
    case bowl   = "BOWL"
}

enum FoodCategory: String, Codable {
    case riceDish = "rice_dish"
    case bread
    case curry
    case meal
    case fullPlatedMeal = "full_plated_meal"  // ✅ ADD THIS
    case snack
    case beverage
    case unknown
}

struct ClassifiedFood: Codable {
    let canonical_food_name: String
    let food_category: FoodCategory
    let portion_type: PortionType
    let default_portion_value: Double
    let original_name: String
    let confidence: Double?
}

struct FoodClassificationResponse: Codable {
    let foods: [ClassifiedFood]
}

// MARK: - Service

final class FoodPortionClassifier {

    static let shared = FoodPortionClassifier()
    private init() {}

    // ⚠️ TEMP: hardcoded for debugging
    private let geminiAPIKey = Secrets.GEMINI_API_KEY


    // MARK: - Debug: List Available Models
    func listAvailableModels() async {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(geminiAPIKey)")!
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            print("🔍 Available Gemini models:")
            if let models = json["models"] as? [[String: Any]] {
                for model in models {
                    if let name = model["name"] as? String,
                       let supportedMethods = model["supportedGenerationMethods"] as? [String],
                       supportedMethods.contains("generateContent") {
                        print("   ✅", name)
                    }
                }
            }
        } catch {
            print("❌ Failed to list models:", error)
        }
    }

    func classifyFoods(from detectedFoods: [DetectedFood]) async -> [ClassifiedFood]? {

        print("\n🔍 ========== FOOD PORTION CLASSIFICATION ==========")
        print("📋 Detected foods:", detectedFoods.map { $0.name })

        let foodList = detectedFoods.map { "- \($0.name)" }.joined(separator: "\n")

        let prompt = """
        Classify the following food item into a standard portion system.

        Return EXACTLY one object inside the foods array.

        Rules:
        - Rice-based dishes → WEIGHT (grams) → food_category: "rice_dish"
        - Breads → COUNT (pieces) → food_category: "bread"
        - Full plated meals → MEAL → food_category: "meal"
        - Curries / gravies → BOWL → food_category: "curry"

        IMPORTANT: food_category must be one of: "rice_dish", "bread", "curry", "meal", "snack", "beverage"

        Detected food:
        \(foodList)

        Return ONLY valid JSON:
        {
          "foods": [
            {
              "canonical_food_name": "Chicken Mandi",
              "food_category": "rice_dish",
              "portion_type": "WEIGHT",
              "default_portion_value": 250,
              "original_name": "Chicken Mandi",
              "confidence": 0.95
            }
          ]
        }
        """

        return await callGemini(prompt: prompt)
    }

    // MARK: - Gemini Call (Hardened)

    private func callGemini(prompt: String) async -> [ClassifiedFood]? {

        print("🔑 Gemini key prefix:", geminiAPIKey.prefix(8))

        // ✅ FIX: Use v1beta with current model (Gemini 2.5 Flash)
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

        guard let url = URL(string: "\(endpoint)?key=\(geminiAPIKey)") else {
            print("❌ Invalid Gemini URL")
            return nil
        }

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 1024
            ]
        ]

        let data = try! JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        // 🚨 IMPORTANT: custom session (fixes nw_connection bug)
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true

        let session = URLSession(configuration: config)

        do {
            let (responseData, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                print("❌ No HTTP response")
                return nil
            }

            print("🌐 Gemini status:", http.statusCode)

            guard http.statusCode == 200 else {
                let body = String(data: responseData, encoding: .utf8) ?? "nil"
                print("❌ Gemini error body:", body)
                return nil
            }

            let json = try JSONSerialization.jsonObject(with: responseData) as! [String: Any]
            let candidates = json["candidates"] as! [[String: Any]]
            let content = candidates[0]["content"] as! [String: Any]
            let parts = content["parts"] as! [[String: Any]]
            let text = parts[0]["text"] as! String

            print("📝 Raw Gemini response:\n", text)

            let cleaned = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let decoded = try JSONDecoder().decode(
                FoodClassificationResponse.self,
                from: cleaned.data(using: .utf8)!
            )

            print("✅ Gemini classification OK")
            return decoded.foods

        } catch {
            print("❌ Gemini request failed:", error)
            return nil
        }
    }
}
