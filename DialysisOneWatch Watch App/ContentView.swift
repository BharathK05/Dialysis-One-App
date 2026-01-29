//
//  ContentView.swift
//  DialysisOneWatch Watch App
//
//  Created by user@22 on 16/12/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        if appState.isLoggedIn {
            NavigationStack {
                HomeView()
            }
        } else {
            LoggedOutWatchView()
        }
    }
}

#Preview {
    ContentView()
}
