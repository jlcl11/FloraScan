//
//  PlantHealthTests.swift
//  FloraScanTests
//
//  Created by José Luis Corral López on 29/4/26.
//

import Testing
import Foundation
@testable import FloraScan

@Suite("Plant Health Score")
struct PlantHealthTests {

    @Test("Health is 1.0 when no tasks exist")
    func healthNoTasks() {
        let plant = Plant(scientificName: "Test", commonName: "Test", nickname: "")
        plant.recalculateHealthScore()
        #expect(plant.healthScore == 1.0)
    }

    @Test("Health is 1.0 when all tasks are future")
    func healthAllFuture() {
        let plant = Plant(scientificName: "Test", commonName: "Test", nickname: "")
        let future = Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now
        let task = CareTask(type: .watering, intervalDays: 7, nextDueAt: future)
        plant.careTasks.append(task)

        plant.recalculateHealthScore()
        #expect(plant.healthScore == 1.0)
    }

    @Test("Health degrades with overdue tasks")
    func healthDegrades() {
        let plant = Plant(scientificName: "Test", commonName: "Test", nickname: "")
        let past = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
        let task = CareTask(type: .watering, intervalDays: 7, nextDueAt: past)
        plant.careTasks.append(task)

        plant.recalculateHealthScore()
        #expect(plant.healthScore < 1.0)
        #expect(plant.healthScore >= 0.0)
    }

    @Test("Health never goes below 0")
    func healthFloor() {
        let plant = Plant(scientificName: "Test", commonName: "Test", nickname: "")
        // Many heavily overdue tasks
        for _ in 0..<10 {
            let longOverdue = Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now
            let task = CareTask(type: .watering, intervalDays: 3, nextDueAt: longOverdue)
            plant.careTasks.append(task)
        }

        plant.recalculateHealthScore()
        #expect(plant.healthScore >= 0.0)
    }

    @Test("Multiple overdue tasks compound penalty")
    func multipleOverdue() {
        let plant1 = Plant(scientificName: "A", commonName: "A", nickname: "")
        let past = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        plant1.careTasks.append(CareTask(type: .watering, intervalDays: 7, nextDueAt: past))

        let plant2 = Plant(scientificName: "B", commonName: "B", nickname: "")
        plant2.careTasks.append(CareTask(type: .watering, intervalDays: 7, nextDueAt: past))
        plant2.careTasks.append(CareTask(type: .fertilizing, intervalDays: 30, nextDueAt: past))

        plant1.recalculateHealthScore()
        plant2.recalculateHealthScore()

        #expect(plant2.healthScore < plant1.healthScore)
    }
}
