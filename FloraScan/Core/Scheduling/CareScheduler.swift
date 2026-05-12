//
//  CareScheduler.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation

nonisolated enum CareScheduler {

    // MARK: - Next watering date

    /// Calculate next watering date considering base interval, light level, and season.
    static func nextWatering(for plant: Plant, from date: Date = .now) -> Date {
        let base = Double(plant.wateringIntervalDays)
        let lightMod = plant.lightLevelValue.modifier
        let seasonMod = seasonalModifier(for: date)
        let adjusted = max(1, Int((base * lightMod * seasonMod).rounded()))
        return Calendar.current.date(byAdding: .day, value: adjusted, to: date) ?? date
    }

    /// Calculate next fertilizing date.
    static func nextFertilizing(for plant: Plant, from date: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: plant.fertilizingIntervalDays, to: date) ?? date
    }

    /// Check if current month is a pruning month for the plant.
    static func shouldPrune(_ plant: Plant, in date: Date = .now) -> Bool {
        let month = Calendar.current.component(.month, from: date)
        return plant.pruningMonths.contains(month)
    }

    // MARK: - Create default care tasks

    /// Create default care tasks for a newly added plant.
    static func createDefaultTasks(for plant: Plant) -> [CareTask] {
        var tasks = [
            CareTask(type: .watering, intervalDays: plant.wateringIntervalDays, nextDueAt: nextWatering(for: plant)),
            CareTask(type: .fertilizing, intervalDays: plant.fertilizingIntervalDays, nextDueAt: nextFertilizing(for: plant))
        ]
        if !plant.pruningMonths.isEmpty {
            tasks.append(CareTask(type: .pruning, intervalDays: 365, nextDueAt: nextPruningDate(months: plant.pruningMonths)))
        }
        return tasks
    }

    // MARK: - Complete task and recalculate

    /// Recalculate next due date after completing a task, and update plant health.
    static func recalculateAfterCompletion(task: CareTask, plant: Plant) {
        task.lastDoneAt = .now
        switch task.type {
        case .watering:
            task.nextDueAt = nextWatering(for: plant)
            plant.lastWateredAt = .now
        case .fertilizing:
            task.nextDueAt = nextFertilizing(for: plant)
            plant.lastFertilizedAt = .now
        case .pruning:
            task.nextDueAt = nextPruningDate(months: plant.pruningMonths)
            plant.lastPrunedAt = .now
        case .repotting:
            task.nextDueAt = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
        case .rotation:
            task.nextDueAt = Calendar.current.date(byAdding: .day, value: task.intervalDays, to: .now) ?? .now
        }
        plant.recalculateHealthScore()
    }

    // MARK: - Seasonal modifier

    /// Summer: water more often (-30%), winter: less often (+40%).
    static func seasonalModifier(for date: Date) -> Double {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 6, 7, 8:  return 0.7   // summer — water more often
        case 12, 1, 2: return 1.4   // winter — water less often
        default:       return 1.0   // spring/autumn
        }
    }

    // MARK: - Private helpers

    private static func nextPruningDate(months: [Int], from date: Date = .now) -> Date {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: date)
        let currentYear = calendar.component(.year, from: date)

        // Find the next pruning month from now
        let sorted = months.sorted()

        // Try this year first
        for month in sorted where month > currentMonth {
            var components = DateComponents()
            components.year = currentYear
            components.month = month
            components.day = 1
            if let d = calendar.date(from: components) { return d }
        }

        // Otherwise next year
        for month in sorted {
            var components = DateComponents()
            components.year = currentYear + 1
            components.month = month
            components.day = 1
            if let d = calendar.date(from: components) { return d }
        }

        // Fallback
        return calendar.date(byAdding: .year, value: 1, to: date) ?? date
    }
}
