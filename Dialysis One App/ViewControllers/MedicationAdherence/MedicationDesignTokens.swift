//
//  MedicationDesignTokens.swift
//  Dialysis One App
//
//  Created by user@1 on 20/11/25.
//

import Foundation
import UIKit

enum MedicationDesignTokens {
    // MARK: - Colors (sRGB Hex)
    enum Colors {
        static let popupBackground = UIColor(red: 0.55, green: 0.89, blue: 0.70, alpha: 0.95) // #8CE3B3
        static let cardBackground = UIColor.white.withAlphaComponent(0.9)
        static let checkmarkActive = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0) // #34C759
        static let checkmarkInactive = UIColor.systemGray4
        static let textPrimary = UIColor.label
        static let textSecondary = UIColor.secondaryLabel
        static let separatorColor = UIColor.separator.withAlphaComponent(0.3)
        static let selectedTabBackground = UIColor.white
        static let unselectedTabBackground = UIColor.clear
    }
    
    // MARK: - Typography
    enum Typography {
        static let medicationName = UIFont.systemFont(ofSize: 16, weight: .semibold)
        static let medicationDescription = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let sectionTitle = UIFont.systemFont(ofSize: 20, weight: .bold)
        static let timeSlotLabel = UIFont.systemFont(ofSize: 15, weight: .semibold)
        static let statusBadge = UIFont.systemFont(ofSize: 15, weight: .medium)
        static let dateLabel = UIFont.systemFont(ofSize: 14, weight: .medium)
    }
    
    // MARK: - Layout
    enum Layout {
        static let popupCornerRadius: CGFloat = 18
        static let cardCornerRadius: CGFloat = 20
        static let checkboxSize: CGFloat = 28
        static let rowHeight: CGFloat = 72
        static let rowPadding: CGFloat = 16
        static let cardPadding: CGFloat = 20
        static let minimumTapTarget: CGFloat = 44
        
        // Shadow
        static let shadowOffset = CGSize(width: 0, height: 4)
        static let shadowRadius: CGFloat = 12
        static let shadowOpacity: Float = 0.15
    }
    
    // MARK: - Animation
    enum Animation {
        static let expansionDuration: TimeInterval = 0.35
        static let expansionDamping: CGFloat = 0.75
        static let checkmarkDuration: TimeInterval = 0.25
        static let checkmarkScale: CGFloat = 1.15
    }
}
