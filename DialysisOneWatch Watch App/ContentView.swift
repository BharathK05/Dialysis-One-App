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

// MARK: - Global Theme Utilities
struct WatchTheme {
    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.14, blue: 0.11),
                    Color(white: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 225/255, green: 245/255, blue: 235/255),
                    Color(red: 200/255, green: 235/255, blue: 225/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.18).opacity(0.9)
            : Color.white.opacity(0.85)
    }
}

struct WatchBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        ZStack {
            WatchTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func watchBackground() -> some View {
        self.modifier(WatchBackgroundModifier())
    }
}
