import Foundation

enum WatchMessageType: String {
    case summary        = "summary"        // iPhone → Watch
    case addWater       = "add_water"      // Watch → iPhone
    case vitals         = "vitals"         // Watch → iPhone
    case alert          = "alert"          // Watch → iPhone
    case auth           = "auth"            // iPhone → Watch
}
