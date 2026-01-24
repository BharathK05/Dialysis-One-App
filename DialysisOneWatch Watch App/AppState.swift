//
//  AppState.swift
//  Dialysis One Watch App
//
//  Created by user@22 on 15/12/25.
//

import Foundation
import Combine

final class AppState: ObservableObject {

    static let shared = AppState()

    @Published private(set) var isLoggedIn: Bool = true

    private init() {}

    // MARK: - Auth handling

    func handleLogout() {
        guard isLoggedIn else { return }

        isLoggedIn = false
        WorkoutManager.shared.stopIfNeeded()
    }

    func handleLogin() {
        guard !isLoggedIn else { return }
        isLoggedIn = true
    }
}
