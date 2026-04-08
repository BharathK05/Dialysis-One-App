import Foundation
import SwiftData

@MainActor
final class ProfileManager {

    static let shared = ProfileManager()

    var container: ModelContainer!
    var context: ModelContext!

    var currentProfile: UserProfile?

    func initializeContainer() {
        do {
            container = try ModelContainer(for:
                UserProfile.self,
                FoodLog.self,
                FluidLog.self,
                MedicationLog.self
            )
            context = ModelContext(container)
            fetchProfile()

            // MARK: - One-time migration from UserDefaults → SwiftData
            let defaults = UserDefaults.standard
            let hasMigrated = defaults.bool(forKey: "didMigrateToSwiftData")

            if !hasMigrated {
                if let profile = currentProfile {
                    // Migrate plain nutrient keys (if they were ever written by old code)
                    let oldProtein = defaults.double(forKey: "protein")
                    let oldSodium = defaults.double(forKey: "sodium")
                    let oldPotassium = defaults.double(forKey: "potassium")

                    if oldProtein > 0 { profile.proteinTarget = oldProtein }
                    if oldSodium > 0  { profile.sodiumTarget  = oldSodium  }
                    if oldPotassium > 0 { profile.potassiumTarget = oldPotassium }

                    // Migrate CKD stage from legacy EditHealthDetailsLocal_v1
                    if let dict = defaults.dictionary(forKey: "EditHealthDetailsLocal_v1") {
                        profile.ckdStage = dict["ckdStage"] as? String ?? ""
                    }

                    profile.lastUpdated = Date()
                    try? context?.save()
                }

                // Mark migration as done (even if no profile exists yet,
                // so we never re-run this block after fresh onboarding)
                defaults.set(true, forKey: "didMigrateToSwiftData")

                // Clean up legacy keys
                defaults.removeObject(forKey: "protein")
                defaults.removeObject(forKey: "sodium")
                defaults.removeObject(forKey: "potassium")
                defaults.removeObject(forKey: "EditHealthDetailsLocal_v1")
            }
            // MARK: - One-time activity-log migration (SavedMeal JSON → FoodLog SwiftData)
            let hasMigratedActivity = defaults.bool(forKey: "didMigrateActivityLogs")
            if !hasMigratedActivity {
                let uid = LocalUserManager.shared.getLocalUserID()
                let mealsKey = "saved_meals_\(uid)"
                if let data = defaults.data(forKey: mealsKey),
                   let oldMeals = try? JSONDecoder().decode([SavedMeal].self, from: data) {
                    for meal in oldMeals {
                        let log = FoodLog(
                            id:        meal.id,
                            dishName:  meal.dishName,
                            mealType:  meal.mealType.rawValue,
                            calories:  meal.calories,
                            protein:   meal.protein,
                            potassium: meal.potassium,
                            sodium:    meal.sodium,
                            quantity:  meal.quantity,
                            timestamp: meal.timestamp,
                            imageData: meal.imageData
                        )
                        context?.insert(log)
                    }
                    try? context?.save()
                    defaults.removeObject(forKey: mealsKey)
                    print("✅ Migrated \(oldMeals.count) meals to SwiftData FoodLog")
                }
                defaults.set(true, forKey: "didMigrateActivityLogs")
            }
        } catch {
            print("Failed to initialize SwiftData Container: \(error)")
        }
    }

    func fetchProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        currentProfile = try? context?.fetch(descriptor).first
    }

    func saveProfile(_ profile: UserProfile) {
        if let existing = currentProfile {
            // Prevent multiple profiles
            updateProfile(existing)
            return
        }
        profile.lastUpdated = Date()
        context?.insert(profile)
        do {
            try context?.save()
            currentProfile = profile
        } catch {
            print("Failed to save profile: \(error)")
        }
    }

    func updateProfile(_ profile: UserProfile, oldWeight: Double? = nil) {
        if profile.isUsingDefaultTargets {
            if oldWeight == nil || oldWeight != profile.weightKg {
                recalculateTargets(for: profile)
            }
        }
        profile.lastUpdated = Date()
        do {
            try context?.save()
            currentProfile = profile
        } catch {
            print("Failed to update profile: \(error)")
        }
    }

    func recalculateTargets(for profile: UserProfile) {
        guard profile.isUsingDefaultTargets else { return }

        let weight = profile.weightKg

        if profile.gender.lowercased() == "male" {
            profile.calorieTarget = weight * 32
        } else {
            profile.calorieTarget = weight * 28
        }

        profile.waterTarget = weight * 30 / 1000.0 // L based on ml
        profile.proteinTarget = 84
        profile.sodiumTarget = 2000
        profile.potassiumTarget = 2000
    }
    
    func resetToDefaults() {
        guard let profile = currentProfile else { return }
        profile.isUsingDefaultTargets = true
        recalculateTargets(for: profile)
        profile.lastUpdated = Date()
        try? context?.save()
    }
}
