//
//  WatchConnectivityManagerPhone.swift
//  Dialysis One App
//
//  Created by user@22 on 10/12/25.
//

import Foundation
import WatchConnectivity
import UserNotifications

final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()
    private let session: WCSession? = WCSession.isSupported() ? .default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }
    
    private enum WatchPayloadType {
        static let addWater = "add_water"
        static let addMedication = "add_medication"
        static let addDiet = "add_diet"
        static let requestSync = "request_sync"
        static let nutritionLookup = "nutrition_lookup"
    }

    // Access latest context
    var latestContext: [String: Any]? {
        return session?.receivedApplicationContext
    }
    
    func notifyLogout() {
        guard let session = session else { return }

        let payload: [String: Any] = [
            "type": "auth",
            "state": "logged_out",
            "timestamp": Date().timeIntervalSince1970
        ]

        do {
            try session.updateApplicationContext(payload)
        } catch {
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    func notifyLogin() {
        guard let session = session else { return }
        
        let payload: [String: Any] = [
            "type": "auth",
            "state": "logged_in",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }

    // Evaluate payload from watch or context (incoming -> iPhone)
    func handleIncomingPayload(_ payload: [String: Any]) {
        
        // 0️⃣ AUTH payloads (sent by iPhone → Watch, ignore on iPhone)
        if payload["type"] as? String == "auth" {
            return
        }
        
        if payload["type"] as? String == WatchPayloadType.addWater {
            handleAddWaterFromWatch(payload)
            return
        }
    
        if payload["type"] as? String == WatchPayloadType.addMedication {
            handleAddMedicationFromWatch(payload)
            return
        }
        
        if payload["type"] as? String == WatchPayloadType.addDiet {
            handleAddDietFromWatch(payload)
            return
        }
        
        if payload["type"] as? String == WatchPayloadType.requestSync {
            sendFullSync()
            return
        }
        
        // Note: nutritionLookup is handled via sendMessage replyHandler in session(_:didReceiveMessage:replyHandler:)

        if payload["alert"] as? Bool == true {
            let hr = payload["heartRate"] as? Double
            let spo2 = payload["spo2"] as? Double

            NotificationEvaluator.shared.evaluate(
                heartRate: hr,
                spo2: spo2,
                timestamp: Date()
            )
            return
        }

        // 2️⃣ SUMMARY from iPhone → Watch (ignore on phone)
        if payload["type"] as? String == "summary" {
            print("Summary payload received on iPhone (ignored).")
            return
        }

        // 3️⃣ VITALS from Watch (normal flow)
        if payload["source"] as? String == "watch" {
            let hr = payload["heartRate"] as? Double
            let spo2 = payload["spo2"] as? Double
            let ts = payload["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970

            NotificationEvaluator.shared.evaluate(
                heartRate: hr,
                spo2: spo2,
                timestamp: Date(timeIntervalSince1970: ts)
            )
            return
        }

        // 4️⃣ Unknown payload (safe ignore)
        print("Unknown WC payload:", payload)
    }
    
    private func handleAddMedicationFromWatch(_ payload: [String: Any]) {

        guard
            let medicationIdString = payload["medicationId"] as? String,
            let medicationId = UUID(uuidString: medicationIdString),
            let timeString = payload["timeOfDay"] as? String
        else {
            print("❌ Invalid add_medication payload:", payload)
            return
        }

        let timeOfDay: TimeOfDay
        switch timeString {
        case "morning": timeOfDay = .morning
        case "afternoon": timeOfDay = .afternoon
        case "night": timeOfDay = .night
        default: return
        }

        MedicationStore.shared.toggleTaken(
            medicationId: medicationId,
            date: Date(),
            timeOfDay: timeOfDay
        )

        NotificationCenter.default.post(name: .medicationDidUpdate, object: nil)

        let progress = MedicationStore.shared.takenCount(for: timeOfDay, date: Date())
        let summary = "\(progress.taken) / \(progress.total) taken"

        sendSummary(food: nil, water: nil, medication: summary)

        print("✅ Medication toggled from Watch:", medicationId)
    }
    
    // MARK: - Handle Diet from Watch
    
    private func handleAddDietFromWatch(_ payload: [String: Any]) {
        guard
            let foodName = payload["foodName"] as? String,
            let quantity = payload["quantity"] as? Int,
            let mealTypeString = payload["mealType"] as? String
        else {
            print("❌ Invalid add_diet payload:", payload)
            return
        }
        
        // Map meal type string to SavedMeal.MealType
        let mealType: SavedMeal.MealType
        switch mealTypeString.lowercased() {
        case "breakfast": mealType = .breakfast
        case "dinner": mealType = .dinner
        default: mealType = .lunch
        }
        
        // Check if Watch sent pre-computed nutrition (new flow)
        let calories: Int
        let potassium: Int
        let sodium: Int
        let protein: Double
        
        if let cal = payload["calories"] as? Int,
           let pot = payload["potassium"] as? Int,
           let sod = payload["sodium"] as? Int,
           let pro = payload["protein"] as? Double {
            // Watch already computed the scaled values
            calories = cal
            potassium = pot
            sodium = sod
            protein = pro
        } else {
            // Legacy fallback: compute from NutritionDatabase
            let nutritionData = NutritionDatabase.shared.lookupDish(byLabel: foodName)
            let scale = Double(quantity) / 100.0
            calories = Int(Double(nutritionData?.calories ?? 100) * scale)
            potassium = Int(Double(nutritionData?.potassium ?? 200) * scale)
            sodium = Int(Double(nutritionData?.sodium ?? 200) * scale)
            protein = Double(nutritionData?.protein ?? 5) * scale
        }
        
        // Save via MealDataManager (single source of truth)
        MealDataManager.shared.saveMeal(
            dishName: foodName,
            calories: calories,
            potassium: potassium,
            sodium: sodium,
            protein: protein,
            quantity: quantity,
            mealType: mealType,
            image: nil
        )
        
        // Send updated summary back to Watch
        let totals = MealDataManager.shared.getTodayTotals()
        sendSummary(
            food: "\(totals.calories) cal today",
            water: nil,
            medication: nil
        )
        
        print("✅ Diet added from Watch: \(foodName) (\(quantity)g) — \(calories) kcal")
    }
    
    // MARK: - Handle Nutrition Lookup from Watch
    
    private func handleNutritionLookupFromWatch(_ payload: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let foodName = payload["foodName"] as? String else {
            replyHandler(["error": "Missing food name"])
            return
        }
        
        print("🔍 Watch requested nutrition lookup for: \(foodName)")
        
        // Step 1: Try local NutritionDatabase first (fast)
        if let dbNutrients = DishTemplateManager.shared.nutrients(forDetectedName: foodName) {
            let reply: [String: Any] = [
                "foodName": dbNutrients.dishName,
                "caloriesPer100g": Int(dbNutrients.calories),
                "proteinPer100g": dbNutrients.protein,
                "potassiumPer100g": Int(dbNutrients.potassium),
                "sodiumPer100g": Int(dbNutrients.sodium),
                "confidence": "high",
                "source": "database"
            ]
            replyHandler(reply)
            print("✅ Replied with DB nutrition for: \(foodName)")
            return
        }
        
        // Step 2: Fallback to Gemini AI
        Task {
            if let aiNutrients = await LLMNutritionService.shared.estimateNutrients(
                forDishName: foodName,
                categoryHint: nil,
                quantityHint: nil
            ) {
                let reply: [String: Any] = [
                    "foodName": aiNutrients.dishName,
                    "caloriesPer100g": Int(aiNutrients.calories),
                    "proteinPer100g": aiNutrients.protein,
                    "potassiumPer100g": Int(aiNutrients.potassium),
                    "sodiumPer100g": Int(aiNutrients.sodium),
                    "confidence": aiNutrients.confidence ?? "moderate",
                    "source": "ai"
                ]
                replyHandler(reply)
                print("✅ Replied with AI nutrition for: \(foodName)")
            } else {
                replyHandler(["error": "Could not estimate nutrition for \(foodName)"])
                print("❌ Failed nutrition lookup for: \(foodName)")
            }
        }
    }

    func sendMedicationList(_ meds: [Medication], timeOfDay: TimeOfDay) {
        guard let session = session else { return }

        let payload: [String: Any] = [
            "type": WatchMessageType.medicationList.rawValue,
            "timeOfDay": timeOfDay.rawValue,
            "medications": meds.map {
                [
                    "id": $0.id.uuidString,
                    "name": $0.name,
                    "dosage": $0.dosage,
                    "isTaken": $0.isTaken(on: Date(), timeOfDay: timeOfDay)
                ]
            }
        ]

        // Use sendMessage for immediate delivery, fallback to transferUserInfo for queued
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { err in
                print("sendMedicationList sendMessage failed:", err.localizedDescription)
                // Fallback: Use transferUserInfo for reliable delivery
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
    }

    
    private func handleAddWaterFromWatch(_ payload: [String: Any]) {

        guard
            let quantity = payload["quantity"] as? Int,
            let fluidType = payload["fluidType"] as? String
        else {
            print("❌ Invalid add_water payload:", payload)
            return
        }

        let uid = FirebaseAuthManager.shared.getUserID() ?? "guest"

        // 1️⃣ Log fluid entry (which persists to SwiftData)
        FluidLogStore.shared.addLog(
            type: fluidType,
            quantity: quantity
        )

        let newTotal = ActivityLogManager.shared.todayFluidTotal()

        // 3️⃣ Notify UI (HomeDashboardViewController listens)
        NotificationCenter.default.post(
            name: .waterDidUpdate,
            object: nil
        )

        let goal = LimitsManager.shared.getFluidLimit()

        sendSummary(
            food: nil,
            water: "\(newTotal) / \(goal) ml",
            medication: nil
        )

        print("✅ Water added from Watch:", quantity, "ml (", fluidType, ")")
    }


    // MARK: - Sending Summary to Watch (Food, Water, Medication)
    
    /// Send partial summary — merges with existing application context
    func sendSummary(food: String?, water: String?, medication: String?) {
        guard let session = session else { return }

        var payload: [String: Any] = [
            "type": WatchMessageType.summary.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let food = food { payload["summary.food"] = food }
        if let water = water { payload["summary.water"] = water }
        if let medication = medication { payload["summary.medication"] = medication }

        // Prefer sendMessage for immediate delivery
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { err in
                print("sendSummary sendMessage failed:", err.localizedDescription)
                // Fallback to applicationContext
                try? session.updateApplicationContext(payload)
            }
        } else {
            do {
                try session.updateApplicationContext(payload)
            } catch {
                print("updateApplicationContext failed:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - Full Sync (push ALL current data to Watch)
    
    func sendFullSync() {
        guard let session = session else { return }
        
        let uid = FirebaseAuthManager.shared.getUserID() ?? "guest"
        
        // Gather all current data
        let waterConsumed = UserDataManager.shared.loadInt("waterConsumed", uid: uid, defaultValue: 0)
        let waterGoal = UserDataManager.shared.loadInt("waterGoal", uid: uid, defaultValue: 2500)
        let dietTotals = MealDataManager.shared.getTodayTotals()
        
        let time = TimeOfDay.current()
        let morningP = MedicationStore.shared.takenCount(for: .morning, date: Date())
        let afternoonP = MedicationStore.shared.takenCount(for: .afternoon, date: Date())
        let nightP = MedicationStore.shared.takenCount(for: .night, date: Date())
        let totalTaken = morningP.taken + afternoonP.taken + nightP.taken
        let totalDoses = morningP.total + afternoonP.total + nightP.total
        
        // Recent food names for Watch suggestions
        let recentMeals = MealDataManager.shared.getAllMeals()
        let recentFoods = Array(Set(recentMeals.map { $0.dishName })).prefix(20)
        
        // Medication list for current time
        let meds = MedicationStore.shared.medicationsFor(timeOfDay: time, date: Date())
        let medsPayload = meds.map { med -> [String: Any] in
            [
                "id": med.id.uuidString,
                "name": med.name,
                "dosage": med.dosage,
                "isTaken": med.isTaken(on: Date(), timeOfDay: time)
            ]
        }
        
        var payload: [String: Any] = [
            "type": WatchMessageType.fullSync.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "summary.food": "\(dietTotals.calories) cal today",
            "summary.water": "\(waterConsumed) / \(waterGoal) ml",
            "summary.medication": "\(totalTaken) / \(totalDoses) taken",
            "recentFoods": Array(recentFoods),
            "medications": medsPayload
        ]
        
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { err in
                print("sendFullSync sendMessage failed:", err.localizedDescription)
                // Fallback
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
        
        print("📊 Full sync sent to Watch")
    }

    // ----- Compatibility overload -----
    func sendSummary(foodText: String?, waterText: String?, medicationText: String?) {
        sendSummary(food: foodText, water: waterText, medication: medicationText)
    }
}



// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleIncomingPayload(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Handle nutrition lookup with reply
        if message["type"] as? String == WatchPayloadType.nutritionLookup {
            handleNutritionLookupFromWatch(message, replyHandler: replyHandler)
            return
        }
        // Default: handle as regular message
        DispatchQueue.main.async {
            self.handleIncomingPayload(message)
        }
        replyHandler([:])
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.handleIncomingPayload(applicationContext)
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            self.handleIncomingPayload(userInfo)
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    )
    {
        if activationState == .activated {
            // Send full sync on activation so Watch has latest data
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.sendFullSync()
            }
        }
        
        print("WC activated on iPhone:", activationState.rawValue, error?.localizedDescription ?? "")

        let s = WCSession.default
        print("Paired:", s.isPaired)
        print("Watch installed:", s.isWatchAppInstalled)
        print("Reachable:", s.isReachable)

        NotificationCenter.default.post(name: .watchStateChanged, object: nil)
    }


    func sessionReachabilityDidChange(_ session: WCSession) {
        NotificationCenter.default.post(name: .watchStateChanged, object: nil)
        
        // When Watch becomes reachable, send fresh data
        if session.isReachable {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sendFullSync()
            }
        }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        NotificationCenter.default.post(name: .watchStateChanged, object: nil)
    }

    // These two methods are required to satisfy the protocol:
    func sessionDidBecomeInactive(_ session: WCSession) {
        // no-op
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
