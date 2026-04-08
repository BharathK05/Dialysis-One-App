//
//  GeminiVisionService.swift
//  Dialysis One App
//
//  Gemini Vision API for Accurate Food Detection
//

import UIKit

struct DetectedFood: Codable {
    let name: String
    let type: String?
    let quantity: String?
    let confidence: String?
    
    enum CodingKeys: String, CodingKey {
        case name, type, quantity, confidence
    }
    
    init(name: String, type: String? = nil, quantity: String? = nil, confidence: String? = nil) {
        self.name = name
        self.type = type
        self.quantity = quantity
        self.confidence = confidence
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? "Unknown Food"
        self.type = try? container.decodeIfPresent(String.self, forKey: .type)
        
        if let qInt = try? container.decodeIfPresent(Int.self, forKey: .quantity) {
            self.quantity = "\(qInt)"
        } else if let qDouble = try? container.decodeIfPresent(Double.self, forKey: .quantity) {
            self.quantity = "\(qDouble)"
        } else {
            self.quantity = try? container.decodeIfPresent(String.self, forKey: .quantity)
        }
        
        if let cDouble = try? container.decodeIfPresent(Double.self, forKey: .confidence) {
            self.confidence = "\(cDouble)"
        } else {
            self.confidence = try? container.decodeIfPresent(String.self, forKey: .confidence)
        }
    }
}

struct FoodDetectionResponse: Codable {
    let detected_foods: [DetectedFood]
}

final class GeminiVisionService {
    static let shared = GeminiVisionService()
    
    // Get your API key from: https://makersuite.google.com/app/apikey
    private let apiKey = Secrets.GEMINI_API_KEY
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    private init() {}
    
    /// Main entry point – call this from the camera flow.
    func detectFood(in image: UIImage) async -> [DetectedFood] {
        print("\n🔍 ========== CALLING GEMINI VISION API ==========")
        
        // Use slightly stronger compression to avoid “message too long” / -1005 issues.
        guard let imageData = prepareImageForGemini(image) else {
            print("❌ Failed to resize image for Gemini")
            print("================================================\n")
            return []
        }

        print("📦 Gemini payload size:", imageData.count / 1024, "KB")

        let base64Image = imageData.base64EncodedString()

        print("✅ Image resized & encoded successfully")

        
        print("✅ Image encoded successfully")
        
        // Prompt: we still rely on text → JSON (no JSON mode to avoid field-name issues)
        let prompt = """
        Analyze this image and detect ALL food items present. For each food item, provide:
        1. Exact dish name (be specific - e.g., "Chicken Biryani" not just "Rice")
        2. Type of food (e.g., "curry", "bread", "rice dish")
        3. Estimated quantity (e.g., "2 rotis", "1 bowl", "1 plate")
        4. A confidence score between 0 and 1 as a string (e.g., "0.92")

        Return ONLY a valid JSON object in this exact format (no markdown, no explanation):

        {
          "detected_foods": [
            {
              "name": "Dish Name",
              "type": "food type",
              "quantity": "estimated quantity",
              "confidence": "0.92"
            }
          ]
        }

        Important:
        - If you see Indian dishes, use their proper names (e.g., "Palak Paneer", "Dal Makhani")
        - Detect every separate food item visible (bread, curry, rice, sides, etc.)
        - Be specific about the dish (not just "curry" - what type of curry?)
        """
        
        // NOTE:
        // Using the Developer API style keys: inlineData + mimeType (this is what
        // was working earlier for you).
        // We also *do not* send responseMimeType here to avoid 400 field errors.
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 1024,
                "thinkingConfig": [
                    "thinkingBudget": 0
                ]
            ]
        ]

        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("❌ Failed to serialize request JSON")
            print("================================================\n")
            return []
        }
        
        let urlString = "\(endpoint)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid Gemini URL")
            print("================================================\n")
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        print("🌐 Sending request to Gemini API...")
        
        do {
            let config = URLSessionConfiguration.ephemeral
            config.waitsForConnectivity = false
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.httpMaximumConnectionsPerHost = 1

            let session = URLSession(configuration: config)

            let (data, response) = try await session.data(for: request)

            
            guard let http = response as? HTTPURLResponse else {
                print("⚠️ Invalid HTTP response object")
                print("================================================\n")
                return []
            }
            
            print("📡 Response status: \(http.statusCode)")
            
            // If Gemini itself returned an error payload, log & bail
            if let topLevel = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = topLevel["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ Gemini API error: \(message)")
                print("📄 Full error payload: \(topLevel)")
                print("================================================\n")
                return []
            }
            
            guard http.statusCode == 200 else {
                print("⚠️ Non-200 status with no 'error' field. Raw body:")
                if let text = String(data: data, encoding: .utf8) {
                    print(text)
                }
                print("================================================\n")
                return []
            }
            
            // Try to parse the content → text → JSON
            if let foods = parseFoodList(from: data) {
                print("✅ Successfully detected \(foods.count) food items:")
                for (index, food) in foods.enumerated() {
                    print("   \(index + 1). \(food.name)")
                    if let type = food.type {
                        print("      Type: \(type)")
                    }
                    if let quantity = food.quantity {
                        print("      Quantity: \(quantity)")
                    }
                    if let conf = food.confidence {
                        print("      Confidence: \(conf)")
                    }
                }
                print("================================================\n")
                return foods
            }
            
            // If we couldn’t parse into FoodDetectionResponse, dump raw text.
            print("⚠️ Could not parse Gemini response into FoodDetectionResponse")
            if let text = String(data: data, encoding: .utf8) {
                print("📄 Raw body:")
                print(text)
            }
            print("================================================\n")
            return []
            
        } catch {
            // Distinguish network errors for easier debugging.
            if let urlError = error as? URLError {
                switch urlError.code {
                case .networkConnectionLost:
                    print("🚨 Network connection lost while calling Gemini (-1005)")
                case .timedOut:
                    print("⏳ Gemini request timed out")
                case .notConnectedToInternet:
                    print("📴 No internet connection on device")
                default:
                    print("❌ URLSession error: \(urlError.code.rawValue) – \(urlError.localizedDescription)")
                }
            } else {
                print("❌ Unexpected error: \(error.localizedDescription)")
            }
            
            print("================================================\n")
            return []
        }
    }
    
    // MARK: - Private helpers
    private func prepareImageForGemini(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1024
        let scale = min(
            maxDimension / image.size.width,
            maxDimension / image.size.height,
            1.0
        )

        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized?.jpegData(compressionQuality: 0.65)
    }

    
    /// Extract the model's text and decode it into FoodDetectionResponse
    private func parseFoodList(from data: Data) -> [DetectedFood]? {
        // JSON structure:
        // {
        //   "candidates": [
        //     {
        //       "content": {
        //         "parts": [ { "text": " {...json... }" } ]
        //       }
        //     }
        //   ]
        // }
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let firstCandidate = candidates.first,
            let content = firstCandidate["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let firstPart = parts.first,
            let text = firstPart["text"] as? String
        else {
            return nil
        }
        
        print("📄 Raw Gemini response text:")
        print(text)
        print("")
        
        // Sometimes models wrap JSON in ```json ... ``` – strip that just in case
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedText.data(using: .utf8) else {
            return nil
        }
        
        if let response = try? JSONDecoder().decode(FoodDetectionResponse.self, from: jsonData) {
            return response.detected_foods
        } else if let arrayResponse = try? JSONDecoder().decode([DetectedFood].self, from: jsonData) {
            return arrayResponse
        } else {
            print("⚠️ JSONDecoder failed for cleaned text – maybe model output wasn't valid JSON.")
            return nil
        }
    }
}
