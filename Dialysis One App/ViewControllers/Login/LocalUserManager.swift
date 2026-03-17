//
//  LocalUserManager.swift
//  Dialysis One App
//
//  Created by user@1 on 05/02/26.
//


//
//  LocalUserManager.swift
//  Dialysis One App
//
//  Local user identity manager - works offline
//

import Foundation

class LocalUserManager {
    
    static let shared = LocalUserManager()
    
    private init() {}
    
    // MARK: - Local User ID
    
    /// Get or create local user ID (UUID-based, persists forever)
    func getOrCreateLocalUserID() -> String {
        if let existingID = UserDefaults.standard.string(forKey: "localUserID") {
            return existingID
        }
        
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "localUserID")
        print("✅ Created new local user ID: \(newID)")
        return newID
    }
    
    /// Get current local user ID (guaranteed to exist)
    func getLocalUserID() -> String {
        return getOrCreateLocalUserID()
    }
    
    // MARK: - Apple ID Integration
    
    /// Save Apple user ID when user signs in with Apple
    func saveAppleUserID(_ appleID: String) {
        UserDefaults.standard.set(appleID, forKey: "appleUserID")
        UserDefaults.standard.set(true, forKey: "hasSignedInWithApple")
        print("✅ Saved Apple User ID: \(appleID)")
    }
    
    /// Get Apple user ID if user has signed in with Apple
    func getAppleUserID() -> String? {
        return UserDefaults.standard.string(forKey: "appleUserID")
    }
    
    /// Check if user has signed in with Apple
    func hasAppleID() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasSignedInWithApple")
    }
    
    // MARK: - User Type
    
    enum UserType {
        case guest
        case appleID
    }
    
    func getUserType() -> UserType {
        return hasAppleID() ? .appleID : .guest
    }
    
    // MARK: - Onboarding Status
    
    func isOnboardingCompleted() -> Bool {
        let localID = getLocalUserID()
        return UserDefaults.standard.bool(forKey: "onboardingCompleted_\(localID)")
    }
    
    func markOnboardingCompleted() {
        let localID = getLocalUserID()
        UserDefaults.standard.set(true, forKey: "onboardingCompleted_\(localID)")
        print("✅ Onboarding marked complete for user: \(localID)")
    }
    
    // MARK: - User Data Migration Helper
    
    /// Migrate old Firebase-based keys to local user ID
    func migrateFromFirebaseIfNeeded(oldFirebaseUID: String?) {
        guard let firebaseUID = oldFirebaseUID else { return }
        
        let localID = getLocalUserID()
        
        // Migrate onboarding status
        if UserDefaults.standard.bool(forKey: "onboardingCompleted_\(firebaseUID)") {
            UserDefaults.standard.set(true, forKey: "onboardingCompleted_\(localID)")
            print("✅ Migrated onboarding status from Firebase")
        }
        
        // Add more migrations as needed for other data
    }
}