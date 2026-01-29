//
//  DialysisOneWatchApp.swift
//  DialysisOneWatch Watch App
//
//  Created by user@22 on 16/12/25.
//

import SwiftUI

@main
struct DialysisOneWatch_Watch_AppApp: App {

    init() {
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    HealthKitManager.shared.requestAuthorization { authorized in
                        if authorized {
                            print("✅ HealthKit authorized — starting workout")
                            WorkoutManager.shared.start()
                        } else {
                            print("❌ HealthKit authorization denied")
                        }
                    }
                }
        }
    }
}

