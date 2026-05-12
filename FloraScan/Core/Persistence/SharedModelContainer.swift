//
//  SharedModelContainer.swift
//  FloraScan
//
//  Created by José Luis Corral López on 12/5/26.
//

import Foundation
import SwiftData

/// Shared ModelContainer factory used by both the main app and the widget extension.
/// Both targets must belong to the same App Group: `group.io.jlcl11.florascan`.
enum SharedModelContainer {
    static let appGroupID = "group.io.jlcl11.florascan"

    static var storeURL: URL {
        containerURL.appendingPathComponent("FloraScan.store")
    }

    static func create() throws -> ModelContainer {
        let schema = Schema(versionedSchema: FloraScanSchemaV1.self)
        let config = ModelConfiguration("FloraScan", schema: schema, url: storeURL)
        return try ModelContainer(
            for: schema,
            migrationPlan: FloraScanMigrationPlan.self,
            configurations: [config]
        )
    }

    private static var containerURL: URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            // Fallback for when App Group is not configured yet (e.g. simulator without entitlement)
            return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        }
        return url
    }
}
