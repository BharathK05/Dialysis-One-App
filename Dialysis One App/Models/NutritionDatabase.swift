import Foundation
import SQLite3

/// Nutritional information for a food item
struct DishNutrients {
    let dishName: String
    let calories: Double
    let protein: Double
    let potassium: Double
    let sodium: Double
    let ckdTag: String?
    let confidence: String?
    let servingSize: String?
    
    // CKD safety flags - REVISED based on Stage 3-4 CKD guidelines
    var sodiumLevel: SafetyLevel {
        // CKD: < 2000mg/day recommended, < 500mg per meal is safe
        if sodium > 800 { return .high }      // High: > 800mg (exceeds meal limit)
        if sodium > 400 { return .moderate }  // Moderate: 400-800mg
        return .low                           // Low: < 400mg
    }
    
    var potassiumLevel: SafetyLevel {
        // CKD: < 2000mg/day recommended, < 600mg per meal is safe
        if potassium > 700 { return .high }      // High: > 700mg
        if potassium > 400 { return .moderate }  // Moderate: 400-700mg
        return .low                              // Low: < 400mg
    }
    
    var proteinLevel: SafetyLevel {
        // CKD: 0.6-0.8g/kg body weight (assume 60kg = 36-48g/day, ~12-15g per meal)
        if protein > 20 { return .high }      // High: > 20g
        if protein > 12 { return .moderate }  // Moderate: 12-20g
        return .low                           // Low: < 12g
    }
}

/// Safety level for CKD monitoring
enum SafetyLevel: String {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "orange"
        case .high: return "red"
        }
    }
}

/// Scaled nutrients with portion multiplier
struct ScaledNutrients {
    let original: DishNutrients
    let multiplier: Double
    
    var calories: Int { Int((original.calories * multiplier).rounded()) }
    var protein: Double { (original.protein * multiplier * 10).rounded() / 10 }
    var potassium: Int { Int((original.potassium * multiplier).rounded()) }
    var sodium: Int { Int((original.sodium * multiplier).rounded()) }
    
    // Re-evaluate safety after scaling
    var sodiumLevel: SafetyLevel {
        let scaled = Double(sodium)
        if scaled > 800 { return .high }
        if scaled > 400 { return .moderate }
        return .low
    }
    
    var potassiumLevel: SafetyLevel {
        let scaled = Double(potassium)
        if scaled > 700 { return .high }
        if scaled > 400 { return .moderate }
        return .low
    }
    
    var proteinLevel: SafetyLevel {
        if protein > 20 { return .high }
        if protein > 12 { return .moderate }
        return .low
    }
}

/// SQLite database manager for nutrition data
final class NutritionDatabase {
    
    static let shared = NutritionDatabase()
    
    private var db: OpaquePointer?
    private let dbFileName = "app_master_dishes_safe_with_sodium.db"
    
    private init() {
        openDatabase()
    }
    
    deinit {
        closeDatabase()
    }
    
    private func openDatabase() {
        guard let dbPath = Bundle.main.path(forResource: dbFileName.replacingOccurrences(of: ".db", with: ""), ofType: "db") else {
            print("❌ Database file '\(dbFileName)' not found in bundle")
            return
        }
        
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("✅ Nutrition database opened successfully")
            print("   Path: \(dbPath)")
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to open database: \(errorMessage)")
            db = nil
        }
    }
    
    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
            print("📕 Database closed")
        }
    }
    
    func lookupDish(byLabel label: String) -> DishNutrients? {
        guard let db = db else {
            print("❌ Database not available")
            return nil
        }
        
        let normalizedLabel = label.lowercased().trimmingCharacters(in: .whitespaces)
        
        let query = """
        SELECT 
            dish_name, kcal, protein_g, potassium_mg, sodium_mg,
            ckd_tag, confidence
        FROM dishes
        WHERE dish_name = '\(normalizedLabel)'
        LIMIT 1
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare query: \(errorMessage)")
            return nil
        }
        
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let dishName = String(cString: sqlite3_column_text(statement, 0))
            let calories = sqlite3_column_double(statement, 1)
            let protein = sqlite3_column_double(statement, 2)
            let potassium = sqlite3_column_double(statement, 3)
            let sodium = sqlite3_column_double(statement, 4)
            let ckdTag = sqlite3_column_text(statement, 5).map { String(cString: $0) }
            let confidence = sqlite3_column_text(statement, 6).map { String(cString: $0) }
            
            print("✅ Found dish: \(dishName)")
            print("   Calories: \(calories) kcal")
            print("   Protein: \(protein)g, K: \(potassium)mg, Na: \(sodium)mg")
            
            return DishNutrients(
                dishName: dishName,
                calories: calories,
                protein: protein,
                potassium: potassium,
                sodium: sodium,
                ckdTag: ckdTag,
                confidence: confidence,
                servingSize: nil
            )
        }
        
        print("⚠️ Dish not found in database: '\(normalizedLabel)'")
        return nil
    }
    
    func searchDishes(byName searchTerm: String) -> [DishNutrients] {
        guard let db = db else { return [] }
        
        let query = """
        SELECT 
            dish_name, kcal, protein_g, potassium_mg, sodium_mg,
            ckd_tag, confidence
        FROM dishes
        WHERE LOWER(dish_name) LIKE ?
        LIMIT 20
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        let searchPattern = "%\(searchTerm.lowercased())%"
        sqlite3_bind_text(statement, 1, searchPattern, -1, nil)
        
        var results: [DishNutrients] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let dishName = String(cString: sqlite3_column_text(statement, 0))
            let calories = sqlite3_column_double(statement, 1)
            let protein = sqlite3_column_double(statement, 2)
            let potassium = sqlite3_column_double(statement, 3)
            let sodium = sqlite3_column_double(statement, 4)
            let ckdTag = sqlite3_column_text(statement, 5).map { String(cString: $0) }
            let confidence = sqlite3_column_text(statement, 6).map { String(cString: $0) }
            
            results.append(DishNutrients(
                dishName: dishName,
                calories: calories,
                protein: protein,
                potassium: potassium,
                sodium: sodium,
                ckdTag: ckdTag,
                confidence: confidence,
                servingSize: nil
            ))
        }
        
        return results
    }
    
    func getAllDishes() -> [String] {
        guard let db = db else { return [] }
        
        let query = "SELECT dish_name FROM dishes ORDER BY dish_name"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        
        defer { sqlite3_finalize(statement) }
        
        var dishes: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let dishName = String(cString: sqlite3_column_text(statement, 0))
            dishes.append(dishName)
        }
        
        return dishes
    }
    
    func testConnection() {
        print("\n🧪 Testing database connection...")
        let dishes = getAllDishes()
        
        if dishes.isEmpty {
            print("❌ No dishes found - check database schema")
        } else {
            print("✅ Found \(dishes.count) dishes in database")
            print("   First 5 dishes:")
            dishes.prefix(5).forEach { print("   - \($0)") }
        }
    }
    
    func testDishLookup() {
        print("\n🧪 Testing dish lookup...")
        
        let testDishes = ["chana_masala", "chana masala", "biryani", "dal_tadka"]
        
        for dishName in testDishes {
            print("\n   Testing: '\(dishName)'")
            if let nutrients = lookupDish(byLabel: dishName) {
                print("   ✅ FOUND: \(nutrients.dishName)")
            } else {
                print("   ❌ NOT FOUND")
            }
        }
    }
}

// MARK: - Portion Size Helper

enum PortionSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var multiplier: Double {
        switch self {
        case .small: return 0.7
        case .medium: return 1.0
        case .large: return 1.5
        }
    }
    
    var emoji: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        }
    }
}
