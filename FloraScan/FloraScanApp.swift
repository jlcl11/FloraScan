//
//  FloraScanApp.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import SwiftData
import UserNotifications
import os

@main
struct FloraScanApp: App {
    private let container: ModelContainer
    private let notificationDelegate: NotificationDelegate

    init() {
        let container: ModelContainer
        let schema = Schema(versionedSchema: FloraScanSchemaV1.self)
        let config = ModelConfiguration("FloraScan", schema: schema)
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: FloraScanMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            Logger.persistence.error("ModelContainer init failed: \(error.localizedDescription). Attempting recovery.")
            // Delete corrupt store and retry
            try? FileManager.default.removeItem(at: config.url)
            do {
                container = try ModelContainer(
                    for: schema,
                    migrationPlan: FloraScanMigrationPlan.self,
                    configurations: [config]
                )
                Logger.persistence.warning("Recovered with fresh database — user data was lost.")
            } catch {
                fatalError("Cannot create ModelContainer after recovery: \(error)")
            }
        }
        self.container = container
        self.notificationDelegate = NotificationDelegate(modelContainer: container)

        UNUserNotificationCenter.current().delegate = notificationDelegate
        Task { @MainActor in
            NotificationsManager.shared.registerCategories()
            let ctx = ModelContext(container)
            ImageStore.cleanupOrphans(context: ctx)
            if let plants = try? ctx.fetch(FetchDescriptor<Plant>()) {
                plants.forEach { $0.recalculateHealthScore() }
                try? ctx.save()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
