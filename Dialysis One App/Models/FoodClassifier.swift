//
//  FoodClassifier.swift
//  Food Recognition Service
//
import UIKit
import CoreML
import Vision

/// Result from food classification
struct FoodPrediction {
    let label: String           // e.g., "dal_tadka"
    let confidence: Float       // 0.0 to 1.0
    let displayName: String     // e.g., "Dal Tadka"
}

/// Service to classify food images using ResNet50 CoreML model
final class FoodClassifier {
    
    // MARK: - Singleton
    static let shared = FoodClassifier()
    
    // MARK: - Properties
    private var model: VNCoreMLModel?
    private let confidenceThreshold: Float = 0.45 // Minimum confidence to consider valid
    
    // MARK: - Initialization
    private init() {
        setupModel()
    }
    
    // MARK: - Model Setup
    
    /// Load the CoreML model
    private func setupModel() {
        do {
            // IMPORTANT: Use the exact name of your .mlpackage file
            // This should match: FoodClassifierResNet50.mlpackage
            let config = MLModelConfiguration()
            config.computeUnits = .all // Use Neural Engine + GPU + CPU
            
            // Use the auto-generated class name from Xcode
            let mlModel = try FoodClassifierResNet50(configuration: config)
            self.model = try VNCoreMLModel(for: mlModel.model)
            
            print("✅ Food classifier model loaded successfully")
        } catch {
            print("❌ Failed to load CoreML model:", error.localizedDescription)
            print("   Make sure FoodClassifierResNet50.mlpackage is:")
            print("   1. In your Xcode project")
            print("   2. Target Membership is checked")
            print("   3. Build has been run at least once")
            self.model = nil
        }
    }
    
    // MARK: - Public API
    
    /// Classify a food image and return top predictions
    /// - Parameters:
    ///   - image: The food image to classify
    ///   - topK: Number of top predictions to return (default: 3)
    ///   - completion: Called with array of predictions or error
    func classify(
        image: UIImage,
        topK: Int = 3,
        completion: @escaping (Result<[FoodPrediction], Error>) -> Void
    ) {
        guard let model = model else {
            completion(.failure(ClassifierError.modelNotLoaded))
            return
        }
        
        guard let ciImage = CIImage(image: image) else {
            completion(.failure(ClassifierError.invalidImage))
            return
        }
        
        // Create Vision request
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else {
                completion(.failure(ClassifierError.noResults))
                return
            }
            
            // Filter and sort by confidence
            let sortedResults = results.sorted { $0.confidence > $1.confidence }
            
            // Convert to FoodPrediction and take top K
            let predictions = sortedResults
                .prefix(topK)
                .map { observation -> FoodPrediction in
                    let label = observation.identifier.lowercased() // Normalize to lowercase
                    let displayName = self.formatDisplayName(from: label)
                    
                    // Ensure confidence is between 0 and 1
                    let normalizedConfidence = max(0.0, min(1.0, observation.confidence))
                    
                    return FoodPrediction(
                        label: label,
                        confidence: normalizedConfidence,
                        displayName: displayName
                    )
                }
            
            print("⚠️ Raw top predictions:")
            for (i, r) in sortedResults.prefix(5).enumerated() {
                print("   \(i+1). \(r.identifier): \(r.confidence)")
            }
            
            completion(.success(Array(predictions)))
        }
        
        // Configure request
        request.imageCropAndScaleOption = .centerCrop
        
        // Perform classification on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if top prediction confidence is acceptable
    func isConfident(_ predictions: [FoodPrediction]) -> Bool {
        guard let topPrediction = predictions.first else { return false }
        return topPrediction.confidence >= confidenceThreshold
    }
    
    /// Convert model label to display name
    /// e.g., "dal_tadka" → "Dal Tadka"
    private func formatDisplayName(from label: String) -> String {
        return label
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    // MARK: - Errors
    
    enum ClassifierError: LocalizedError {
        case modelNotLoaded
        case invalidImage
        case noResults
        case lowConfidence
        
        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                return "ML model could not be loaded. Check if FoodClassifierResNet50.mlpackage is in project."
            case .invalidImage:
                return "Invalid image format"
            case .noResults:
                return "No classification results"
            case .lowConfidence:
                return "Low confidence in prediction"
            }
        }
    }
}
