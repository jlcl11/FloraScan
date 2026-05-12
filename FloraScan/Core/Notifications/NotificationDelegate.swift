//
//  NotificationDelegate.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import UserNotifications
import SwiftData
import os

/// Handles notification actions. Uses Task @MainActor to keep ModelContext on the main actor
/// while still being able to await async work (e.g. rescheduling notifications).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let taskIDString = userInfo["taskID"] as? String,
              let taskID = UUID(uuidString: taskIDString) else { return }

        let actionID = response.actionIdentifier
        let container = modelContainer

        await Task { @MainActor in
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<CareTask>(predicate: #Predicate { $0.id == taskID })

            guard let task = try? context.fetch(descriptor).first,
                  let plant = task.plant else { return }

            switch actionID {
            case "WATERED":
                CareScheduler.recalculateAfterCompletion(task: task, plant: plant)
                context.safeSave()
                Logger.notifications.info("Task completed via notification: \(task.type.displayName)")

            case "SNOOZE_1D":
                task.nextDueAt = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
                context.safeSave()
                await CareReminderScheduler.schedule(task: task)
                Logger.notifications.info("Task snoozed 1 day: \(task.type.displayName)")

            default:
                break
            }
        }.value
    }

    /// Show notification banner even when app is in foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
