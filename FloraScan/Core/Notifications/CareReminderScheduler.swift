//
//  CareReminderScheduler.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import UserNotifications
import os

enum CareReminderScheduler {

    /// Schedule a local notification for a care task at 8:30 on the due date.
    @MainActor
    static func schedule(task: CareTask) async {
        guard let plant = task.plant else { return }

        // Cancel any existing notification for this task
        if let existingID = task.notificationID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [existingID]
            )
        }

        let content = UNMutableNotificationContent()
        content.title = title(for: task.type, plant: plant)
        content.body = body(for: task.type, plant: plant)
        content.sound = .default
        content.categoryIdentifier = "CARE_TASK"
        content.userInfo = [
            "plantID": plant.id.uuidString,
            "taskID": task.id.uuidString
        ]

        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: task.nextDueAt
        )
        components.hour = 8
        components.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Don't schedule notifications for past dates
        if let nextFire = trigger.nextTriggerDate(), nextFire <= .now {
            Logger.notifications.debug("Skipping notification for past date: \(task.nextDueAt)")
            return
        }

        let identifier = task.notificationID ?? UUID().uuidString
        task.notificationID = identifier

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            Logger.notifications.info("Scheduled reminder for \(plant.commonName) — \(task.type.displayName)")
        } catch {
            Logger.notifications.error("Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    /// Cancel all pending notifications for a specific plant.
    @MainActor
    static func cancelAll(for plant: Plant) {
        let ids = plant.careTasks.compactMap(\.notificationID)
        guard !ids.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Schedule reminders for all pending tasks of a plant.
    @MainActor
    static func scheduleAll(for plant: Plant) async {
        for task in plant.careTasks {
            await schedule(task: task)
        }
    }

    // MARK: - Message builders

    private static func title(for type: CareType, plant: Plant) -> String {
        let name = plant.nickname.isEmpty ? plant.commonName : plant.nickname
        return switch type {
        case .watering: "\(name) needs water 💧"
        case .pruning: "Time to prune \(name) ✂️"
        case .fertilizing: "\(name) needs fertilizer ✨"
        case .repotting: "\(name) needs a new pot 🪴"
        case .rotation: "Time to rotate \(name) 🔄"
        }
    }

    private static func body(for type: CareType, plant: Plant) -> String {
        switch type {
        case .watering:
            "It's been \(plant.wateringIntervalDays) days since the last watering."
        default:
            "Tap to see details."
        }
    }
}

