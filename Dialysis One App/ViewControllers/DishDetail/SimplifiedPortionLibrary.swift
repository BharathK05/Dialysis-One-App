//
//  SimplifiedPortionLibrary.swift
//  Dialysis One App
//
//  Fixed portion system: Plate, Grams (per gram), Oz (per oz)
//

import Foundation

struct PortionOption {
    let id: String
    let label: String
    let grams: Double  // Base grams for calculation
    let icon: String
    let ml: Int? = nil
    
    // Calculate actual grams based on portion type
    func calculateGrams() -> Double {
        // For plate: returns grams value (e.g., 250g for 1 plate)
        // For grams/oz: returns 1 (because quantity is already in grams/oz)
        if id == "plate" {
            return grams
        } else {
            return 1.0  // For grams and oz, the quantity itself is the amount
        }
    }
}

struct PortionHelpItem {
    let imageName: String
    let label: String
    let volume: String
}

class PortionLibrary {
    static let standard: [PortionOption] = [
        PortionOption(id: "plate", label: "Plate", grams: 250, icon: "ðŸ½ï¸"),
        PortionOption(id: "grams", label: "Grams", grams: 1, icon: "âš–ï¸"),
        PortionOption(id: "oz", label: "Oz", grams: 28.35, icon: "ðŸ”¢")  // 1 oz = 28.35g
    ]
    
    static let helpItems: [PortionHelpItem] = [
        PortionHelpItem(
            imageName: "fork.knife.circle",
            label: "Plate",
            volume: "~250g per plate"
        ),
        PortionHelpItem(
            imageName: "scalemass",
            label: "Grams",
            volume: "Exact weight"
        ),
        PortionHelpItem(
            imageName: "number.circle",
            label: "Oz (Ounce)",
            volume: "~28.35g per oz"
        )
    ]
    
    static func portion(byId id: String) -> PortionOption? {
        return standard.first { $0.id == id }
    }
    
    static func portion(byLabel label: String) -> PortionOption? {
        return standard.first { $0.label.lowercased() == label.lowercased() }
    }
}
