//
//  LoggedOutWatchView.swift
//  DialysisOne Watch App
//

import SwiftUI

struct LoggedOutWatchView: View {

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone")
                .font(.title2)

            Text("Open Dialysis One on iPhone")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
