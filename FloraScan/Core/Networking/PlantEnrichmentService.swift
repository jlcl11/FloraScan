//
//  PlantEnrichmentService.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation
import SwiftData
import os

enum PlantEnrichmentService {

    /// Enrich a plant with care data from Perenual and description from Wikipedia.
    /// Skips if already enriched within the last 30 days.
    @MainActor
    static func enrichIfNeeded(plant: Plant, context: ModelContext) async {
        // Check 30-day cache
        if let lastEnriched = plant.lastEnrichedAt,
           Date.now.timeIntervalSince(lastEnriched) < 30 * 24 * 3600 {
            return
        }

        // Sequential — Plant is @Model (not Sendable), can't parallelize
        let perenualOk = await enrichFromPerenual(plant: plant)
        guard !Task.isCancelled else { return }
        let wikiOk = await enrichFromWikipedia(plant: plant)
        guard !Task.isCancelled else { return }

        // Only mark as enriched if at least one source succeeded
        if perenualOk || wikiOk {
            plant.lastEnrichedAt = .now
            context.safeSave()
        }
    }

    @MainActor
    @discardableResult
    private static func enrichFromPerenual(plant: Plant) async -> Bool {
        guard let client = PerenualClient() else { return false }

        do {
            let species = try await client.searchSpecies(query: plant.scientificName)
            guard let match = species.first else { return false }

            let isFirstEnrichment = plant.perenualID == nil
            plant.perenualID = match.id

            let care = try await client.careDetails(speciesID: match.id)

            // Only overwrite care data on first enrichment (don't clobber user customizations)
            if isFirstEnrichment {
                plant.wateringIntervalDays = care.wateringFrequency.intervalDays
                if !care.pruningMonths.isEmpty {
                    plant.pruningMonths = care.pruningMonths
                }
                for task in plant.careTasks where task.type == .watering {
                    task.intervalDays = care.wateringFrequency.intervalDays
                }
            }

            Logger.network.info("Enriched \(plant.scientificName) from Perenual (ID: \(match.id))")
            return true
        } catch {
            Logger.network.debug("Perenual enrichment failed for \(plant.scientificName): \(error.localizedDescription)")
            return false
        }
    }

    @MainActor
    @discardableResult
    private static func enrichFromWikipedia(plant: Plant) async -> Bool {
        if let existing = plant.descriptionExtract, !existing.isEmpty { return true }

        let client = WikipediaClient()
        if let summary = await client.summary(scientificName: plant.scientificName) {
            plant.descriptionExtract = summary
            return true
        }
        return false
    }
}
