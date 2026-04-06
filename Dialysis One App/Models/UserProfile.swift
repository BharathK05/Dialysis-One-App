import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var gender: String
    var age: Int

    var heightCm: Double
    var weightKg: Double

    var calorieTarget: Double
    var waterTarget: Double
    var proteinTarget: Double
    var sodiumTarget: Double
    var potassiumTarget: Double

    var isUsingDefaultTargets: Bool
    var lastUpdated: Date
    var ckdStage: String

    init(
        id: UUID = UUID(),
        name: String,
        gender: String,
        age: Int,
        heightCm: Double,
        weightKg: Double,
        calorieTarget: Double,
        waterTarget: Double,
        proteinTarget: Double = 84,     // Default 70 * 1.2
        sodiumTarget: Double = 2000,
        potassiumTarget: Double = 2000,
        isUsingDefaultTargets: Bool,
        lastUpdated: Date = Date(),
        ckdStage: String = ""
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.calorieTarget = calorieTarget
        self.waterTarget = waterTarget
        self.proteinTarget = proteinTarget
        self.sodiumTarget = sodiumTarget
        self.potassiumTarget = potassiumTarget
        self.isUsingDefaultTargets = isUsingDefaultTargets
        self.lastUpdated = lastUpdated
        self.ckdStage = ckdStage
    }

    @Transient var bmi: Double {
        let heightM = heightCm / 100
        guard heightM > 0 else { return 0 }
        return weightKg / (heightM * heightM)
    }
}
