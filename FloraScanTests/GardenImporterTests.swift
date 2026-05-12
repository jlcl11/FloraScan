//
//  GardenImporterTests.swift
//  FloraScanTests
//
//  Created by José Luis Corral López on 29/4/26.
//

import Testing
import Foundation
import SwiftData
@testable import FloraScan

@Suite("GardenImporter Validation")
@MainActor
struct GardenImporterTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Plant.self, PlantPhoto.self, CareTask.self,
            configurations: config
        )
        return ModelContext(container)
    }

    // MARK: - Valid Import

    @Test("Imports a valid plant with all fields")
    func validImport() throws {
        let context = try makeContext()
        let export = GardenExport(
            plants: [
                PlantExport.stub(scientificName: "Olea europaea", commonName: "Olivo")
            ],
            exportedAt: .now,
            appVersion: "1.0"
        )

        let result = GardenImporter.importExport(export, context: context)

        #expect(result.plantsImported == 1)
        #expect(result.errors.isEmpty)

        let descriptor = FetchDescriptor<Plant>()
        let plants = try context.fetch(descriptor)
        #expect(plants.count == 1)
        #expect(plants.first?.scientificName == "Olea europaea")
        #expect(plants.first?.commonName == "Olivo")
    }

    // MARK: - Validation Failures

    @Test("Rejects plant with empty scientific name")
    func emptyScientificName() throws {
        let context = try makeContext()
        let export = GardenExport(
            plants: [PlantExport.stub(scientificName: "", commonName: "Test")],
            exportedAt: .now,
            appVersion: "1.0"
        )

        let result = GardenImporter.importExport(export, context: context)
        #expect(result.plantsImported == 0)
        #expect(!result.errors.isEmpty)
    }

    @Test("Rejects plant with zero watering interval")
    func zeroWatering() throws {
        let context = try makeContext()
        let export = GardenExport(
            plants: [PlantExport.stub(scientificName: "Test", commonName: "T", wateringDays: 0)],
            exportedAt: .now,
            appVersion: "1.0"
        )

        let result = GardenImporter.importExport(export, context: context)
        #expect(result.plantsImported == 0)
    }

    @Test("Rejects plant with invalid pruning months")
    func invalidPruningMonths() throws {
        let context = try makeContext()
        let export = GardenExport(
            plants: [PlantExport.stub(scientificName: "Test", commonName: "T", pruningMonths: [0, 13])],
            exportedAt: .now,
            appVersion: "1.0"
        )

        let result = GardenImporter.importExport(export, context: context)
        #expect(result.plantsImported == 0)
    }

    // MARK: - Partial Import

    @Test("Imports valid plants and skips invalid ones")
    func partialImport() throws {
        let context = try makeContext()
        let export = GardenExport(
            plants: [
                PlantExport.stub(scientificName: "Olea europaea", commonName: "Olivo"),
                PlantExport.stub(scientificName: "", commonName: "Invalid"),
                PlantExport.stub(scientificName: "Rosa gallica", commonName: "Rosa"),
            ],
            exportedAt: .now,
            appVersion: "1.0"
        )

        let result = GardenImporter.importExport(export, context: context)
        #expect(result.plantsImported == 2)
        #expect(result.errors.count == 1)
    }
}

// MARK: - Test Helpers

extension PlantExport {
    static func stub(
        scientificName: String,
        commonName: String,
        wateringDays: Int = 7,
        pruningMonths: [Int] = [3]
    ) -> PlantExport {
        PlantExport(
            nickname: "",
            scientificName: scientificName,
            commonName: commonName,
            acquisitionDate: .now,
            locationLabel: "",
            wateringIntervalDays: wateringDays,
            fertilizingIntervalDays: 30,
            pruningMonths: pruningMonths,
            notes: "",
            photoBase64: nil
        )
    }
}
