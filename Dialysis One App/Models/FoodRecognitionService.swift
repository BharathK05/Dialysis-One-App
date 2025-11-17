//
//  FoodRecognitionService.swift
//  Complete service: Model Prediction + Database Lookup
//
import UIKit

/// Complete result with prediction and nutrients
struct FoodRecognitionResult {
    let prediction: FoodPrediction      // From ML model
    let nutrients: DishNutrients?       // From database (nil if not found)
    let alternativePredictions: [FoodPrediction]  // Top 3-5 alternatives
    
    var isHighConfidence: Bool {
        prediction.confidence >= 0.45
    }
    
    var hasNutrients: Bool {
        nutrients != nil
    }
    
    var needsManualSelection: Bool {
        !isHighConfidence || !hasNutrients
    }
}

/// Main service to recognize food and fetch nutrients
final class FoodRecognitionService {
    
    // MARK: - Singleton
    static let shared = FoodRecognitionService()
    
    // MARK: - Properties
    private let classifier = FoodClassifier.shared
    private let database = NutritionDatabase.shared
    
    private init() {}
    
    // MARK: - Public API
    
    /// Complete food recognition pipeline
    /// - Parameters:
    ///   - image: Food image to analyze
    ///   - completion: Result with prediction and nutrients
    func recognizeFood(
        image: UIImage,
        completion: @escaping (Result<FoodRecognitionResult, Error>) -> Void
    ) {
        print("\n🔍 Starting food recognition pipeline...")
        
        // Step 1: Run ML model classification
        classifier.classify(image: image, topK: 5) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let predictions):
                guard let topPrediction = predictions.first else {
                    completion(.failure(RecognitionError.noPredictions))
                    return
                }
                
                print("✅ Model prediction: \(topPrediction.displayName) (\(String(format: "%.1f%%", topPrediction.confidence * 100)))")
                
                // Step 2: Lookup nutrients in database
                // Step 2: Lookup nutrients in database
                print("🔍 Looking up in database: '\(topPrediction.label)'")
                let nutrients = self.database.lookupDish(byLabel: topPrediction.label)

                // DEBUG: If not found, run test
                if nutrients == nil {
                    print("⚠️ Lookup failed! Running diagnostic test...")
                    self.database.testDishLookup()
                }
                
                if nutrients != nil {
                    print("✅ Nutrients found in database")
                } else {
                    print("⚠️ Nutrients not found for '\(topPrediction.label)'")
                }
                
                // Step 3: Return complete result
                let recognitionResult = FoodRecognitionResult(
                    prediction: topPrediction,
                    nutrients: nutrients,
                    alternativePredictions: Array(predictions.dropFirst())
                )
                
                completion(.success(recognitionResult))
                
            case .failure(let error):
                print("❌ Classification failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    /// Lookup specific dish by name (for manual selection)
    func lookupDish(byName name: String) -> DishNutrients? {
        return database.lookupDish(byLabel: name)
    }
    
    /// Search dishes (for manual search)
    func searchDishes(query: String) -> [DishNutrients] {
        return database.searchDishes(byName: query)
    }
}

// MARK: - Errors

enum RecognitionError: LocalizedError {
    case noPredictions
    case dishNotInDatabase
    case lowConfidence
    
    var errorDescription: String? {
        switch self {
        case .noPredictions:
            return "No predictions returned from model"
        case .dishNotInDatabase:
            return "Dish not found in nutrition database"
        case .lowConfidence:
            return "Low confidence prediction - please select manually"
        }
    }
}
