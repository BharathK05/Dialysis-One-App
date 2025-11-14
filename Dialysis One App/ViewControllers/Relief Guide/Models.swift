//
//  Models.swift
//  ReliefGuide
//
//  Created by user@100 on 12/11/25.
//

import Foundation

struct CureItem {
    let text: String
    let isGood: Bool   // true = ✅, false = ❌
}

struct SymptomDetail {
    let title: String
    let reason: String
    let cures: [CureItem]
}
