//
//  GardenExport.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation
import UniformTypeIdentifiers
import UIKit

extension UTType {
    static let florascanGarden = UTType(exportedAs: "io.jlcl11.florascan.garden")
}

nonisolated struct GardenExport: Codable, Sendable {
    let plants: [PlantExport]
    let exportedAt: Date
    let appVersion: String
}

nonisolated struct PlantExport: Codable, Sendable {
    let nickname: String
    let scientificName: String
    let commonName: String
    let acquisitionDate: Date
    let locationLabel: String
    let wateringIntervalDays: Int
    let fertilizingIntervalDays: Int
    let pruningMonths: [Int]
    let notes: String
    let photoBase64: String?

    @MainActor
    init(from plant: Plant) {
        self.nickname = plant.nickname
        self.scientificName = plant.scientificName
        self.commonName = plant.commonName
        self.acquisitionDate = plant.acquisitionDate
        self.locationLabel = plant.locationLabel
        self.wateringIntervalDays = plant.wateringIntervalDays
        self.fertilizingIntervalDays = plant.fertilizingIntervalDays
        self.pruningMonths = plant.pruningMonths
        self.notes = plant.notes

        if let photo = plant.photos.first(where: \.isPrimary) ?? plant.photos.first,
           let img = ImageStore.load(fileName: photo.fileName),
           let data = img.jpegData(compressionQuality: 0.5) {
            self.photoBase64 = data.base64EncodedString()
        } else {
            self.photoBase64 = nil
        }
    }
}
