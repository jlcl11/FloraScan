//
//  NotificationsManager.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import UserNotifications

@MainActor
final class NotificationsManager {
    static let shared = NotificationsManager()

    private init() {}

    /// Request notification authorization. Returns true if granted.
    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .ephemeral:
            return false
        @unknown default:
            return false
        }
    }

    /// Register notification categories with custom actions.
    func registerCategories() {
        let wateredAction = UNNotificationAction(
            identifier: "WATERED",
            title: "Done ✓",
            options: []
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_1D",
            title: "Tomorrow",
            options: []
        )

        let wateringCategory = UNNotificationCategory(
            identifier: "CARE_TASK",
            actions: [wateredAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([wateringCategory])
    }
}
