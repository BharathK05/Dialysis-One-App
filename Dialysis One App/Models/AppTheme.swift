import UIKit

struct AppTheme {
    static let background = UIColor { trait in
        trait.userInterfaceStyle == .dark 
            ? UIColor(red: 0.08, green: 0.14, blue: 0.11, alpha: 1.0) 
            : UIColor(red: 0.78, green: 0.93, blue: 0.82, alpha: 1.0)
    }
    
    // MARK: - Gradient Colors (used by addTopGradientBackground across all VCs)
    static let gradientTop = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.14, blue: 0.11, alpha: 1.0)
            : UIColor(red: 225/255, green: 245/255, blue: 235/255, alpha: 1.0)
    }
    
    static let gradientBottom = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.05, alpha: 1.0)
            : UIColor(red: 200/255, green: 235/255, blue: 225/255, alpha: 1.0)
    }
    
    // MARK: - Card Colors
    static let dietCardBase = UIColor { trait in
        trait.userInterfaceStyle == .dark 
            ? UIColor(red: 0.6, green: 0.45, blue: 0.2, alpha: 1.0) 
            : UIColor(red: 0.95, green: 0.84, blue: 0.63, alpha: 1.0)
    }
    
    static let waterCardBase = UIColor { trait in
        trait.userInterfaceStyle == .dark 
            ? UIColor(red: 0.1, green: 0.35, blue: 0.45, alpha: 1.0) 
            : UIColor(red: 0.67, green: 0.85, blue: 0.93, alpha: 1.0)
    }
    
    static let pillCardBase = UIColor { trait in
        trait.userInterfaceStyle == .dark 
            ? UIColor(red: 0.15, green: 0.4, blue: 0.25, alpha: 1.0) 
            : UIColor(red: 0.55, green: 0.89, blue: 0.70, alpha: 1.0)
    }
    
    static let cardBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark 
            ? UIColor(white: 0.15, alpha: 1.0) 
            : UIColor.white.withAlphaComponent(0.6)
    }
    
    // MARK: - Glassmorphism Card (for Watch card, report cards, etc.)
    static let glassCard = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.15, alpha: 0.9)
            : UIColor.white.withAlphaComponent(0.9)
    }
    
    static let glassCardLight = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.12, alpha: 0.7)
            : UIColor.white.withAlphaComponent(0.7)
    }
    
    // MARK: - Text Colors
    static let textPrimary = UIColor.label
    
    static let textSecondary = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.65, alpha: 1.0)
            : UIColor(white: 0.30, alpha: 1.0)
    }
    
    // MARK: - Icon Colors
    static let iconPrimary = UIColor { trait in
        trait.userInterfaceStyle == .dark ? .white : .black
    }
    
    // MARK: - Button Background
    static let buttonBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.18, alpha: 1.0)
            : UIColor(white: 0.96, alpha: 1.0)
    }
}
