//
//  UserData.swift
//  Dialysis One App
//

import Foundation

class UserDataManager {

    static let shared = UserDataManager()

    private init() {}

    // MARK: - Helper to get current user ID
    
    private func getCurrentUserID() -> String {
        return LocalUserManager.shared.getLocalUserID()
    }

    // MARK: - Key Generation
    
    func key(_ name: String, uid: String) -> String {
        return "\(name)_\(uid)"
    }
    
    // Convenience method using current user
    func key(_ name: String) -> String {
        let uid = getCurrentUserID()
        return "\(name)_\(uid)"
    }

    // MARK: - Load Methods
    
    func loadInt(_ name: String, uid: String, defaultValue: Int) -> Int {
        let value = UserDefaults.standard.integer(forKey: key(name, uid: uid))
        return value == 0 ? defaultValue : value
    }
    
    // Using current user
    func loadInt(_ name: String, defaultValue: Int) -> Int {
        return loadInt(name, uid: getCurrentUserID(), defaultValue: defaultValue)
    }

    func loadDouble(_ name: String, uid: String, defaultValue: Double) -> Double {
        let val = UserDefaults.standard.double(forKey: key(name, uid: uid))
        return val == 0 ? defaultValue : val
    }
    
    // Using current user
    func loadDouble(_ name: String, defaultValue: Double) -> Double {
        return loadDouble(name, uid: getCurrentUserID(), defaultValue: defaultValue)
    }

    // MARK: - Save Methods
    
    func save(_ name: String, value: Any, uid: String) {
        UserDefaults.standard.set(value, forKey: key(name, uid: uid))
    }
    
    // Using current user
    func save(_ name: String, value: Any) {
        save(name, value: value, uid: getCurrentUserID())
    }
}
