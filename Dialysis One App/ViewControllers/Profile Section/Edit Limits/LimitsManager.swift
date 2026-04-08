//
//  LimitsManager.swift
//  Dialysis One App
//
//  Created by user@1 on 26/11/25.
//


import Foundation

class LimitsManager {
    static let shared = LimitsManager()
    
    private init() {}
    
    private var uid: String {
        return FirebaseAuthManager.shared.getUserID() ?? "guest"
    }
    
    // MARK: - Keys
    // Keeping for migration reference
    private let potassiumKey = "limit_potassium"
    private let sodiumKey = "limit_sodium"
    private let proteinKey = "limit_protein"
    
    // MARK: - Default Values
    private let defaultPotassium = 2000
    private let defaultSodium = 2000
    private let defaultProtein = 84 // 70 * 1.2
    
    private var profile: UserProfile? {
        ProfileManager.shared.currentProfile
    }
    
    // MARK: - Get Limits
    
    func getCalorieLimit() -> Int {
        return Int(profile?.calorieTarget ?? 2000)
    }
    
    func getPotassiumLimit() -> Int {
        return Int(profile?.potassiumTarget ?? Double(defaultPotassium))
    }
    
    func getSodiumLimit() -> Int {
        return Int(profile?.sodiumTarget ?? Double(defaultSodium))
    }
    
    func getProteinLimit() -> Int {
        return Int(profile?.proteinTarget ?? Double(defaultProtein))
    }
    
    func getFluidLimit() -> Int {
        // Return water target in ml (L * 1000)
        return Int((profile?.waterTarget ?? 2.5) * 1000)
    }
    
    // MARK: - Set Limits
    
    func setCalorieLimit(_ value: Int) {
        if let profile = profile {
            profile.calorieTarget = Double(value)
            profile.isUsingDefaultTargets = false
            Task { @MainActor in
                ProfileManager.shared.updateProfile(profile)
                self.postUpdateNotification()
            }
        } else {
            postUpdateNotification()
        }
    }
    
    func setPotassiumLimit(_ value: Int) {
        if let profile = profile {
            profile.potassiumTarget = Double(value)
            profile.isUsingDefaultTargets = false
            Task { @MainActor in
                ProfileManager.shared.updateProfile(profile)
                self.postUpdateNotification()
            }
        } else {
            postUpdateNotification()
        }
    }
    
    func setSodiumLimit(_ value: Int) {
        if let profile = profile {
            profile.sodiumTarget = Double(value)
            profile.isUsingDefaultTargets = false
            Task { @MainActor in
                ProfileManager.shared.updateProfile(profile)
                self.postUpdateNotification()
            }
        } else {
            postUpdateNotification()
        }
    }
    
    func setProteinLimit(_ value: Int) {
        if let profile = profile {
            profile.proteinTarget = Double(value)
            profile.isUsingDefaultTargets = false
            Task { @MainActor in
                ProfileManager.shared.updateProfile(profile)
                self.postUpdateNotification()
            }
        } else {
            postUpdateNotification()
        }
    }
    
    func setFluidLimit(_ value: Int) {
        if let profile = profile {
            profile.waterTarget = Double(value) / 1000.0
            profile.isUsingDefaultTargets = false
            Task { @MainActor in
                ProfileManager.shared.updateProfile(profile)
                self.postUpdateNotification()
            }
        } else {
            postUpdateNotification()
        }
    }
    
    // MARK: - Notification
    
    private func postUpdateNotification() {
        NotificationCenter.default.post(name: .limitsDidUpdate, object: nil)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let limitsDidUpdate = Notification.Name("limitsDidUpdate")
}
