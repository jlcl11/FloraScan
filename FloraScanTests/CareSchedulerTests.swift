//
//  CareSchedulerTests.swift
//  FloraScanTests
//
//  Created by José Luis Corral López on 29/4/26.
//

import Testing
import Foundation
@testable import FloraScan

@Suite("CareScheduler")
struct CareSchedulerTests {

    // MARK: - Seasonal Modifier

    @Test("Summer months return 0.7 modifier")
    func summerModifier() {
        for month in [6, 7, 8] {
            let date = makeDate(month: month)
            #expect(CareScheduler.seasonalModifier(for: date) == 0.7)
        }
    }

    @Test("Winter months return 1.4 modifier")
    func winterModifier() {
        for month in [12, 1, 2] {
            let date = makeDate(month: month)
            #expect(CareScheduler.seasonalModifier(for: date) == 1.4)
        }
    }

    @Test("Spring/autumn months return 1.0 modifier")
    func neutralModifier() {
        for month in [3, 4, 5, 9, 10, 11] {
            let date = makeDate(month: month)
            #expect(CareScheduler.seasonalModifier(for: date) == 1.0)
        }
    }

    // MARK: - Next Watering

    @Test("Next watering considers base interval and light")
    func nextWateringBasic() {
        let plant = Plant(scientificName: "Test", commonName: "Test", nickname: "")
        plant.wateringIntervalDays = 10
        plant.lightLevelValue = .medium // modifier = 1.0

        let now = Date.now
        let next = CareScheduler.nextWatering(for: plant, from: now)

        let days = Calendar.current.dateComponents([.day], from: now, to: next).day ?? 0
        // In spring/autumn (modifier 1.0), medium light (1.0): 10 * 1.0 * 1.0 = 10 days
        // In summer: 10 * 1.0 * 0.7 = 7 days
        // In winter: 10 * 1.0 * 1.4 = 14 days
        #expect(days > 0)
        #expect(days <= 14)
    }

    @Test("Direct sunlight shortens watering interval")
    func directLightReducesInterval() {
        let plantDirect = Plant(scientificName: "A", commonName: "A", nickname: "")
        plantDirect.wateringIntervalDays = 10
        plantDirect.lightLevelValue = .direct // 0.7

        let plantLow = Plant(scientificName: "B", commonName: "B", nickname: "")
        plantLow.wateringIntervalDays = 10
        plantLow.lightLevelValue = .low // 1.3

        let now = Date.now
        let directNext = CareScheduler.nextWatering(for: plantDirect, from: now)
        let lowNext = CareScheduler.nextWatering(for: plantLow, from: now)

        #expect(directNext < lowNext)
    }

    // MARK: - Should Prune

    @Test("shouldPrune returns true for current month if in list")
    func shouldPruneCurrentMonth() {
        let month = Calendar.current.component(.month, from: .now)
        let plant = Plant(scientificName: "Test", commonName: "Test", nickname: "")
        plant.pruningMonths = [month]

        #expect(CareScheduler.shouldPrune(plant))
    }

    @Test("shouldPrune returns false when month not in list")
    func shouldPruneWrongMonth() {
        let month = Calendar.current.component(.month, from: .now)
        let otherMonth = (month % 12) + 1
        let plant = Plant(scientificName: "Test", commonName: "Test", nickname: "")
        plant.pruningMonths = [otherMonth]

        #expect(!CareScheduler.shouldPrune(plant))
    }

    // MARK: - Create Default Tasks

    @Test("createDefaultTasks generates watering and fertilizing at minimum")
    func defaultTasksCreated() {
        let plant = Plant(scientificName: "Olea europaea", commonName: "Olivo", nickname: "")
        plant.wateringIntervalDays = 7
        plant.fertilizingIntervalDays = 30
        plant.pruningMonths = [3, 10]

        let tasks = CareScheduler.createDefaultTasks(for: plant)

        let types = tasks.map(\.type)
        #expect(types.contains(.watering))
        #expect(types.contains(.fertilizing))
        #expect(types.contains(.pruning))
        #expect(tasks.count == 3)
    }

    @Test("createDefaultTasks skips pruning if no months set")
    func noPruningWithoutMonths() {
        let plant = Plant(scientificName: "Test", commonName: "Test", nickname: "")
        plant.pruningMonths = []

        let tasks = CareScheduler.createDefaultTasks(for: plant)
        #expect(!tasks.map(\.type).contains(.pruning))
    }

    // MARK: - Helpers

    private func makeDate(month: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = month
        components.day = 15
        return Calendar.current.date(from: components) ?? .now
    }
}
