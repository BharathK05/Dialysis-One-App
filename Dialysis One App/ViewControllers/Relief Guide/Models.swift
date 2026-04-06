//
// Models.swift
//

import Foundation
import UIKit

struct CureItem {
    let text: String
    let isGood: Bool          // true = ✅, false = ❌
    let imageName: String?    // optional thumbnail for this cure (asset name or file path)
}

enum Severity: Int {
    case low = 0
    case moderate = 1
    case high = 2
    
    var color: UIColor {
        switch self {
        case .low: return .systemGreen
        case .moderate: return .systemYellow
        case .high: return .systemRed
        }
    }
    
    var text: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
}

struct SymptomDetail {
    let title: String
    let reason: String           // short line used in the list
    let detailedReason: String   // full description shown in detail screen
    let imageName: String?       // optional main image for the symptom (asset name or file path)
    var severity: Severity = .low
    let cures: [CureItem]
}

struct ActionContext {
    let explanation: String
    let steps: [String]
    let meta: String?
    let isTrackable: Bool
}

func resolveContext(for title: String, isGood: Bool) -> ActionContext {
    let lower = title.lowercased()
    
    if !isGood {
        if lower.contains("ignore") && lower.contains("headache") {
            return ActionContext(
                explanation: "Persistent headaches after dialysis may indicate blood pressure imbalance or fluid shifts. Ignoring them can delay necessary medical attention and worsen the condition.",
                steps: [],
                meta: nil,
                isTrackable: false
            )
        } else if lower.contains("caffeine") || lower.contains("salt") {
            return ActionContext(
                explanation: "High caffeine or salt intake can worsen blood pressure fluctuations and increase dehydration risk, making post-dialysis recovery harder.",
                steps: [],
                meta: nil,
                isTrackable: false
            )
        } else {
            return ActionContext(
                explanation: "Avoid this to keep your body stabilized after treatment and reduce the risk of severe side effects.",
                steps: [],
                meta: nil,
                isTrackable: false
            )
        }
    }
    
    if lower.contains("stand up slowly") {
        return ActionContext(
            explanation: "After dialysis, your blood pressure may drop. Standing up too quickly can cause dizziness or fainting.",
            steps: ["Sit for 1-2 minutes before standing", "Use support (chair/rail)", "Stand gradually"],
            meta: "Transition: 2-5 minutes",
            isTrackable: false
        )
    } else if lower.contains("elevate your legs") {
        return ActionContext(
            explanation: "Elevating your legs helps improve blood circulation and stabilize blood pressure.",
            steps: ["Lie down comfortably", "Raise legs slightly above heart level", "Use pillows for support"],
            meta: "Duration: 10-15 minutes",
            isTrackable: false
        )
    } else if lower.contains("sit or lie down") {
        return ActionContext(
            explanation: "Sitting or lying down immediately prevents falls and helps your body recover faster.",
            steps: ["Stop movement immediately", "Sit or lie flat", "Take slow breaths"],
            meta: "When: As soon as dizziness starts",
            isTrackable: false
        )
    } else if lower.contains("stretch") {
        return ActionContext(
            explanation: "Light stretching relieves muscle cramps by improving circulation and flexibility without putting excessive strain on your heart.",
            steps: ["Neck rolls (x5)", "Shoulder shrugs (x10)", "Gentle torso twists"],
            meta: "Duration: 5 mins",
            isTrackable: true
        )
    } else if lower.contains("rest") || lower.contains("sleep") || lower.contains("dim room") {
        return ActionContext(
            explanation: "Proper rest allows your body to re-calibrate fluid levels and recover from the intense filtration process.",
            steps: ["Find a quiet, dim room", "Limit screen time before resting", "Use comfortable support pillows"],
            meta: "Goal: 30-60 mins of uninterrupted rest",
            isTrackable: true
        )
    } else if lower.contains("hydrate") || lower.contains("water") || lower.contains("fluid") {
        return ActionContext(
            explanation: "Hydrating within prescribed limits prevents sudden fluid shifts while easing headache symptoms.",
            steps: ["Sip slowly, do not chug", "Track your ounces", "Stop once you reach your daily limit"],
            meta: "Goal: Stay within limit",
            isTrackable: true
        )
    } else if lower.contains("meals") || lower.contains("snacks") || lower.contains("crackers") {
        return ActionContext(
            explanation: "Light, dry snacks help settle acid imbalances in the stomach caused by toxic shifts.",
            steps: ["Eat plain, dry snacks", "Avoid spicy or heavy foods", "Wait 1 hour before laying completely flat"],
            meta: "When: At onset of nausea",
            isTrackable: true
        )
    } else if lower.contains("care team") || lower.contains("doctor") {
        return ActionContext(
            explanation: "Medical professionals can adjust your fluid removal rate to mitigate severe symptoms.",
            steps: ["Record frequency of symptoms", "Call your dialysis center", "Follow their adjusted guidelines"],
            meta: nil,
            isTrackable: false
        )
    } else if lower.contains("blood pressure") {
        return ActionContext(
            explanation: "Keeping a digital log of your vitals helps the care team identify patterns.",
            steps: ["Use a digital BP cuff on the non-access arm", "Record time and readings in your log"],
            meta: nil,
            isTrackable: true
        )
    } else {
        // generic trackable fallback for any Good recommendations
        return ActionContext(
            explanation: "Consistency is key. Follow this guidance to support your dialysis recovery process.",
            steps: ["Follow the instruction carefully", "Do not rush"],
            meta: "Daily habit",
            isTrackable: true
        )
    }
}
