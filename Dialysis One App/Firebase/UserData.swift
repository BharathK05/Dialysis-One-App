//
//  UseraData.swift
//  Dialysis One App
//
//  Created by user@22 on 21/11/25.
//

import Foundation

class UserDataManager {

    static let shared = UserDataManager()

    private init() {}

    func key(_ name: String, uid: String) -> String {
        return "\(name)_\(uid)"
    }

    func loadInt(_ name: String, uid: String, defaultValue: Int) -> Int {
        return UserDefaults.standard.integer(forKey: key(name, uid: uid)) == 0
        ? defaultValue
        : UserDefaults.standard.integer(forKey: key(name, uid: uid))
    }

    func loadDouble(_ name: String, uid: String, defaultValue: Double) -> Double {
        let val = UserDefaults.standard.double(forKey: key(name, uid: uid))
        return val == 0 ? defaultValue : val
    }

    func save(_ name: String, value: Any, uid: String) {
        UserDefaults.standard.set(value, forKey: key(name, uid: uid))
    }
}

