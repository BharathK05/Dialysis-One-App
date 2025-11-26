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
    private let caloriesKey = "limit_calories"
    private let potassiumKey = "limit_potassium"
    private let sodiumKey = "limit_sodium"
    private let proteinKey = "limit_protein"
    private let fluidKey = "limit_fluid"
    
    // MARK: - Default Values
    private let defaultCalories = 2000
    private let defaultPotassium = 2000
    private let defaultSodium = 2000
    private let defaultProtein = 84 // 70 * 1.2
    private let defaultFluid = 250
    
    // MARK: - Get Limits
    
    func getCalorieLimit() -> Int {
        return UserDataManager.shared.loadInt(caloriesKey, uid: uid, defaultValue: defaultCalories)
    }
    
    func getPotassiumLimit() -> Int {
        return UserDataManager.shared.loadInt(potassiumKey, uid: uid, defaultValue: defaultPotassium)
    }
    
    func getSodiumLimit() -> Int {
        return UserDataManager.shared.loadInt(sodiumKey, uid: uid, defaultValue: defaultSodium)
    }
    
    func getProteinLimit() -> Int {
        return UserDataManager.shared.loadInt(proteinKey, uid: uid, defaultValue: defaultProtein)
    }
    
    func getFluidLimit() -> Int {
        return UserDataManager.shared.loadInt(fluidKey, uid: uid, defaultValue: defaultFluid)
    }
    
    // MARK: - Set Limits
    
    func setCalorieLimit(_ value: Int) {
        UserDataManager.shared.save(caloriesKey, value: value, uid: uid)
        postUpdateNotification()
    }
    
    func setPotassiumLimit(_ value: Int) {
        UserDataManager.shared.save(potassiumKey, value: value, uid: uid)
        postUpdateNotification()
    }
    
    func setSodiumLimit(_ value: Int) {
        UserDataManager.shared.save(sodiumKey, value: value, uid: uid)
        postUpdateNotification()
    }
    
    func setProteinLimit(_ value: Int) {
        UserDataManager.shared.save(proteinKey, value: value, uid: uid)
        postUpdateNotification()
    }
    
    func setFluidLimit(_ value: Int) {
        UserDataManager.shared.save(fluidKey, value: value, uid: uid)
        postUpdateNotification()
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