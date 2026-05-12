//
//  GardenImporter.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation
import SwiftData
import os

enum GardenImporter {

    enum ImportError: Error, LocalizedError {
        case fileTooLarge
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .fileTooLarge: "The file is too large (maximum 10 MB)."
            case .invalidFormat: "The file is not a valid FloraScan format."
            }
        }
    }

    struct ImportResult {
        let plantsImported: Int
        let errors: [String]
    }

    private static let maxFileSize = 10_000_000 // 10 MB

    /// Import plants from a .florascan file URL.
    @MainActor
    static func importFile(url: URL, context: ModelContext) throws -> ImportResult {
        // Validate file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int ?? 0
        guard fileSize < maxFileSize else {
            throw ImportError.fileTooLarge
        }

        let data = try Data(contentsOf: url)

        let export: GardenExport
        do {
            export = try JSONDecoder().decode(GardenExport.self, from: data)
        } catch {
            throw ImportError.invalidFormat
        }

        return importExport(export, context: context)
    }

    /// Import plants from a decoded GardenExport.
    @MainActor
    static func importExport(_ export: GardenExport, context: ModelContext) -> ImportResult {
        var imported = 0
        var errors: [String] = []
        var importedPlants: [Plant] = []

        for plantExport in export.plants {
            // Validate required fields
            let sciName = plantExport.scientificName.trimmingCharacters(in: .whitespaces)
            guard !sciName.isEmpty else {
                errors.append("Plant without scientific name, skipped.")
                continue
            }
            guard plantExport.wateringIntervalDays > 0 else {
                errors.append("\(plantExport.commonName): invalid watering interval, skipped.")
                continue
            }
            guard plantExport.pruningMonths.allSatisfy((1...12).contains) else {
                errors.append("\(plantExport.commonName): invalid pruning months, skipped.")
                continue
            }

            let plant = Plant(
                scientificName: sciName,
                commonName: plantExport.commonName,
                nickname: plantExport.nickname
            )
            plant.locationLabel = plantExport.locationLabel
            plant.wateringIntervalDays = plantExport.wateringIntervalDays
            plant.fertilizingIntervalDays = max(1, plantExport.fertilizingIntervalDays)
            plant.pruningMonths = plantExport.pruningMonths
            plant.notes = plantExport.notes
            plant.acquisitionDate = plantExport.acquisitionDate

            // Import photo with sanitized filename
            if let base64 = plantExport.photoBase64,
               base64.count < 5_000_000, // ~3.7 MB decoded max
               let photoData = Data(base64Encoded: base64) {
                let fileName = "\(plant.id.uuidString).jpg"
                if ImageStore.save(data: photoData, fileName: fileName) {
                    let photo = PlantPhoto(fileName: fileName, isPrimary: true)
                    plant.photos.append(photo)
                }
            }

            plant.careTasks.append(contentsOf: CareScheduler.createDefaultTasks(for: plant))

            context.insert(plant)
            importedPlants.append(plant)
            imported += 1
        }

        do {
            try context.save()

            // Schedule notifications for imported plants
            let plants = importedPlants
            Task {
                let granted = await NotificationsManager.shared.requestAuthorizationIfNeeded()
                if granted {
                    for plant in plants {
                        await CareReminderScheduler.scheduleAll(for: plant)
                    }
                }
            }
        } catch {
            Logger.persistence.error("Failed to save imported plants: \(error.localizedDescription)")
            errors.append("Save error: \(error.localizedDescription)")
        }
        Logger.persistence.info("Imported \(imported) plants from garden export")
        return ImportResult(plantsImported: imported, errors: errors)
    }
}
