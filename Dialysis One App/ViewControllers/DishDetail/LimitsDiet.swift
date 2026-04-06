//
//  LimitsDiet.swift
//  Dialysis One App
//
//  Legacy wrapper — now a thin proxy over LimitsManager (SwiftData-backed).
//  Kept for call-site compatibility in DishDetailViewController.
//  DO NOT add any new UserDefaults reads here.
//

import Foundation

// MARK: - DailyLimits (kept for any external type references)

struct DailyLimits {
    let potassiumMg: Int
    let sodiumMg: Int
    let proteinG: Int
    let caloriesKcal: Int
}

// MARK: - LimitsDiet (proxy → LimitsManager)

final class LimitsDiet {

    static let shared = LimitsDiet()
    private init() {}

    private var proxy: LimitsManager { LimitsManager.shared }

    // MARK: - Getters (all delegate to SwiftData-backed LimitsManager)

    func getPotassiumLimit() -> Int { proxy.getPotassiumLimit() }
    func getSodiumLimit()    -> Int { proxy.getSodiumLimit()    }
    func getProteinLimit()   -> Int { proxy.getProteinLimit()   }
    func getCalorieLimit()   -> Int { proxy.getCalorieLimit()   }
    func getFluidLimit()     -> Int { proxy.getFluidLimit()     }

    /// Computed snapshot for any code that still holds a `DailyLimits` value.
    var currentLimits: DailyLimits {
        DailyLimits(
            potassiumMg:  proxy.getPotassiumLimit(),
            sodiumMg:     proxy.getSodiumLimit(),
            proteinG:     proxy.getProteinLimit(),
            caloriesKcal: proxy.getCalorieLimit()
        )
    }
}

// MARK: - Notification (compatibility alias)

extension Notification.Name {
    /// Alias kept so any existing observers continue to compile.
    static let limitsUpdate = Notification.Name("limitsDidUpdate")
}
