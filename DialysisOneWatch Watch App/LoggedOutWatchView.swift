//
//  LoggedOutWatchView.swift
//  Dialysis One App
//
//  Created by user@22 on 16/12/25.
//


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
