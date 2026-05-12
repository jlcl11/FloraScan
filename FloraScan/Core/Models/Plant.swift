//
//  Plant.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation
import SwiftData

@Model
final class Plant {
    @Attribute(.unique) var id: UUID = UUID()
    var nickname: String = ""
    var scientificName: String = ""
    var commonName: String = ""
    var locationLabel: String = ""
    var lightLevel: String = "medium"
    var acquisitionDate: Date = Date()
    var healthScore: Double = 1.0
    var notes: String = ""
    var createdAt: Date = Date()
    var lastWateredAt: Date?
    var lastPrunedAt: Date?
    var lastFertilizedAt: Date?

    // External identification
    var plantNetGBIFID: Int?
    var perenualID: Int?

    // Care profile
    var wateringIntervalDays: Int = 7
    var pruningMonths: [Int] = []
    var fertilizingIntervalDays: Int = 30

    // Enrichment
    var familyName: String?
    var descriptionExtract: String?
    var lastEnrichedAt: Date?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \PlantPhoto.plant)
    var photos: [PlantPhoto] = []

    @Relationship(deleteRule: .cascade, inverse: \CareTask.plant)
    var careTasks: [CareTask] = []

    var lightLevelValue: LightLevel {
        get { LightLevel(rawValue: lightLevel) ?? .medium }
        set { lightLevel = newValue.rawValue }
    }

    init(scientificName: String, commonName: String, nickname: String) {
        self.scientificName = scientificName
        self.commonName = commonName
        self.nickname = nickname
    }

    /// Recalculate health score based on overdue care tasks.
    /// 1.0 = all tasks up to date, degrades as tasks become overdue.
    func recalculateHealthScore() {
        let now = Date.now
        guard !careTasks.isEmpty else { healthScore = 1.0; return }
        let totalPenalty = careTasks.reduce(into: 0.0) { penalty, task in
            guard task.nextDueAt < now else { return }
            let overdueDays = Calendar.current.dateComponents([.day], from: task.nextDueAt, to: now).day ?? 0
            let ratio = Double(overdueDays) / Double(max(1, task.intervalDays))
            penalty += min(0.5, ratio * 0.15)
        }
        healthScore = max(0.0, 1.0 - totalPenalty)
    }
}
