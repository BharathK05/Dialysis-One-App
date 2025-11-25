//
// Models.swift
//

import Foundation

struct CureItem {
    let text: String
    let isGood: Bool          // true = ✅, false = ❌
    let imageName: String?    // optional thumbnail for this cure (asset name or file path)
}

struct SymptomDetail {
    let title: String
    let reason: String           // short line used in the list
    let detailedReason: String   // full description shown in detail screen
    let imageName: String?       // optional main image for the symptom (asset name or file path)
    let cures: [CureItem]
}
