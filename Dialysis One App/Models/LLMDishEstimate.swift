//
//  LLMDishEstimate.swift
//  Dialysis One App
//
//  Created by user@1 on 08/12/25.
//


//
//  LLMNutritionService.swift
//  Dialysis One App
//
//  Step 3: Fallback to Gemini text model when DB/templates
//          do not contain a dish.
//

import Foundation

/// Response shape we expect from Gemini (JSON)
struct LLMDishEstimate: Codable {
    let dish_name: String
    let calories_per_100g: Double
    let protein_g_per_100g: Double
    let potassium_mg_per_100g: Double
    let sodium_mg_per_100g: Double
    let serving_size: String?
    let ckd_safety_tag: String?
    let confidence: Double?
}

/// Wrapper to decode `{"dish_estimate": { ... }}` if we want it
private struct LLMDishEstimateEnvelope: Codable {
    let dish_estimate: LLMDishEstimate
}

/// Service: calls Gemini text model and converts to `DishNutrients`
final class LLMNutritionService {
    
    static let shared = LLMNutritionService()
    
    private init() {}
    
    private let apiKey = Secrets.GEMINI_API_KEY
    private let modelName = "gemini-2.5-flash"
    
    /// Main API – ask Gemini for an approximate nutrition profile
    func estimateNutrients(
        forDishName dishName: String,
        categoryHint: String? = nil,
        quantityHint: String? = nil
    ) async -> DishNutrients? {
        
        guard !apiKey.isEmpty else {
            print("❌ LLMNutritionService: Missing Gemini API key")
            return nil
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            print("❌ LLMNutritionService: Invalid URL")
            return nil
        }
        
        // Build prompt
        var lines: [String] = []
        lines.append("You are a renal dietitian.")
        lines.append("Estimate nutrition values for the given Indian dish.")
        lines.append("Return **only** JSON in the exact format requested.")
        lines.append("")
        lines.append("Dish name: \(dishName)")
        if let categoryHint, !categoryHint.isEmpty {
            lines.append("Category hint: \(categoryHint)")
        }
        if let quantityHint, !quantityHint.isEmpty {
            lines.append("Portion hint: \(quantityHint)")
        }
        lines.append("")
        lines.append("Use IFCT / reliable Indian food tables as reference.")
        lines.append("Assume values are **per 100 grams of edible portion**.")
        lines.append("Focus only on Calories (kcal), Protein (g), Potassium (mg), Sodium (mg).")
        lines.append("Be conservative for CKD stage 3–4 (i.e. do not underestimate risk).")
        lines.append("")
        lines.append("Respond ONLY with JSON in this exact shape:")
        lines.append("""
        {
          "dish_estimate": {
            "dish_name": "string",
            "calories_per_100g": 0,
            "protein_g_per_100g": 0,
            "potassium_mg_per_100g": 0,
            "sodium_mg_per_100g": 0,
            "serving_size": "example human readable serving",
            "ckd_safety_tag": "low | moderate | high",
            "confidence": 0.0
          }
        }
        """)
        
        let promptText = lines.joined(separator: "\n")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": promptText]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json",
                "temperature": 0.3
            ]

        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("❌ LLMNutritionService: Could not encode request body")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse {
                print("\n📡 LLMNutritionService status: \(http.statusCode)")
            }
            
            guard let jsonString = String(data: data, encoding: .utf8) else {
                print("⚠️ LLMNutritionService: Could not decode body as UTF-8")
                return nil
            }
            
            print("📄 LLM raw body:\n\(jsonString)\n")
            
            // Gemini with responseMimeType sends JSON directly (no candidates[] wrapper),
            // but we also tolerate the regular text-in-candidates format.
            if let estimate = try? JSONDecoder().decode(LLMDishEstimateEnvelope.self, from: data) {
                return convertToDishNutrients(estimate.dish_estimate)
            }
            
            if let estimate = try? JSONDecoder().decode(LLMDishEstimate.self, from: data) {
                return convertToDishNutrients(estimate)
            }
            
            // Fallback: maybe Gemini wrapped JSON in text inside candidates → try to parse that.
            if let innerData = extractJSONFromCandidatesBody(data: data) {
                if let envelope = try? JSONDecoder().decode(LLMDishEstimateEnvelope.self, from: innerData) {
                    return convertToDishNutrients(envelope.dish_estimate)
                }
                if let estimate = try? JSONDecoder().decode(LLMDishEstimate.self, from: innerData) {
                    return convertToDishNutrients(estimate)
                }
            }
            
            print("⚠️ LLMNutritionService: Could not decode estimate JSON")
            return nil
            
        } catch {
            print("❌ LLMNutritionService: network / decoding error – \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Helpers
    
    /// Convert the LLM estimate (per 100g) into our `DishNutrients` model.
    private func convertToDishNutrients(_ e: LLMDishEstimate) -> DishNutrients {
        print("✅ LLM estimate parsed for \(e.dish_name)")
        
        return DishNutrients(
            dishName: e.dish_name,
            calories: e.calories_per_100g,
            protein: e.protein_g_per_100g,
            potassium: e.potassium_mg_per_100g,
            sodium: e.sodium_mg_per_100g,
            ckdTag: e.ckd_safety_tag,
            confidence: e.confidence.map { String($0) },
            servingSize: e.serving_size, isCompositeFinal: false
        )
    }
    
    /// If Gemini returned the usual `candidates[].content.parts[].text` style,
    /// pull out the JSON text and turn it into Data.
    private func extractJSONFromCandidatesBody(data: Data) -> Data? {
        struct CandidateResponse: Codable {
            struct Candidate: Codable {
                struct Content: Codable {
                    struct Part: Codable {
                        let text: String?
                    }
                    let parts: [Part]?
                }
                let content: Content?
            }
            let candidates: [Candidate]?
        }
        
        guard let wrapper = try? JSONDecoder().decode(CandidateResponse.self, from: data),
              let text = wrapper.candidates?.first?.content?.parts?.first?.text else {
            return nil
        }
        
        return text.data(using: .utf8)
    }
}
