//
//  SchemaVersions.swift
//  FloraScan
//
//  Created by José Luis Corral López on 29/4/26.
//

import SwiftData

/// V1: Initial schema — Plant, PlantPhoto, CareTask
enum FloraScanSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Plant.self, PlantPhoto.self, CareTask.self]
    }
}

/// Migration plan — add new stages here as the schema evolves.
enum FloraScanMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FloraScanSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // Future migrations go here, e.g.:
        // .lightweight(fromVersion: FloraScanSchemaV1.self, toVersion: FloraScanSchemaV2.self)
        []
    }
}
