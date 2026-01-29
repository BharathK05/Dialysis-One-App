//
//  Dialysis_One_Watch_AppApp.swift
//  Dialysis One Watch App Watch App
//
//  Created by user@22 on 15/12/25.
//

import SwiftUI

@main
struct Dialysis_One_Watch_Watch_AppApp: App {

    init() {
        // Ensure WatchConnectivity starts immediately
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
}
