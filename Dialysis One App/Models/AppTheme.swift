import UIKit

struct AppTheme {
    static let background = UIColor { trait in
        trait.userInterfaceStyle == .dark 
            ? UIColor(red: 0.08, green: 0.14, blue: 0.11, alpha: 1.0) 
            : UIColor(red: 0.78, green: 0.93, blue: 0.82, alpha: 1.0)
    }
    
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
}
