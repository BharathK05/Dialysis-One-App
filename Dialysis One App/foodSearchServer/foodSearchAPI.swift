//
//  foodSearchAPI.swift
//  Dialysis One App
//
//  Created by user@1 on 21/12/25.
//

import Foundation
import SwiftUI

struct SearchDishResponse: Codable {
    let confidence: Double
    let results: [DishSuggestionDTO]
}

struct DishSuggestionDTO: Codable {
    let name: String
    let description: String
    let tags: [String]
}

final class FoodSearchAPI {

    static let shared = FoodSearchAPI()
    private init() {}

    func searchDishes(query: String, userId: String) async throws -> SearchDishResponse {

        let url = URL(string: "https://YOUR_BACKEND_URL/search/dishes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "query": query,
            "user_id": userId,
            "limit": 10
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(SearchDishResponse.self, from: data)
    }
}
