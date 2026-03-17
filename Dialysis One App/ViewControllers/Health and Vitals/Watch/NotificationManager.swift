//
//  NotificationManager.swift
//  Dialysis One App
//
//  Created by user@22 on 10/12/25.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Notif permission: \(granted) \(error?.localizedDescription ?? "")")
        }
    }

    func postAlert(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req) { error in
            if let error = error { print("Notif error: \(error.localizedDescription)") }
        }
    }
}
