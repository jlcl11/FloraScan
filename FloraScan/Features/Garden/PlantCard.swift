//
//  PlantCard.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct PlantCard: View {
    let plant: Plant

    private var primaryPhotoFileName: String? {
        (plant.photos.first(where: \.isPrimary) ?? plant.photos.first)?.fileName
    }

    private var nextTask: CareTask? {
        plant.careTasks
            .sorted { $0.nextDueAt < $1.nextDueAt }
            .first
    }

    private var isUrgent: Bool {
        guard let task = nextTask else { return false }
        return Calendar.current.isDateInToday(task.nextDueAt)
            || task.nextDueAt < Date.now
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            ZStack(alignment: .topTrailing) {
                photoView
                    .frame(maxWidth: .infinity)
                    .aspectRatio(3/4, contentMode: .fit)
                    .clipped()
                    .clipShape(.rect(cornerRadius: Radius.cardMedium))

                HealthRing(value: plant.healthScore, size: 28, stroke: 2.5)
                    .padding(Spacing.s2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.nickname.isEmpty ? plant.commonName : plant.nickname)
                    .font(.fsSubhead)
                    .foregroundStyle(Palette.Dynamic.textPrimary)
                    .lineLimit(1)

                Text(plant.scientificName)
                    .font(.scientificName)
                    .foregroundStyle(Palette.Dynamic.textTertiary)
                    .lineLimit(1)

                if let task = nextTask {
                    taskLabel(task)
                }
            }
            .padding(.horizontal, Spacing.s1)
            .padding(.bottom, Spacing.s1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Photo

    private var photoView: some View {
        AsyncPlantImage(fileName: primaryPhotoFileName)
    }

    // MARK: - Task Label

    private func taskLabel(_ task: CareTask) -> some View {
        HStack(spacing: 4) {
            Image(systemName: task.type.symbolName)
                .font(.fsCaption2)
            Text(taskText(task))
        }
        .font(.fsCaption1)
        .foregroundStyle(isUrgent ? Palette.clay700 : Palette.Dynamic.textSecondary)
        .lineLimit(1)
    }

    private func taskText(_ task: CareTask) -> String {
        let calendar = Calendar.current
        if task.nextDueAt < Date.now || calendar.isDateInToday(task.nextDueAt) {
            return "Today"
        }
        if calendar.isDateInTomorrow(task.nextDueAt) {
            return "Tomorrow"
        }
        let days = calendar.dateComponents([.day], from: .now, to: task.nextDueAt).day ?? 0
        return "In \(days) days"
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        let name = plant.nickname.isEmpty ? plant.commonName : plant.nickname
        let sci = plant.scientificName
        let health = Int(plant.healthScore * 100)
        var desc = "\(name), \(sci), health \(health)%"
        if let task = nextTask {
            desc += ", next \(task.type.displayName.lowercased()) \(taskText(task).lowercased())"
        }
        return desc
    }
}

#Preview {
    let plant = Plant(scientificName: "Olea europaea", commonName: "Olivo", nickname: "Mi olivo")
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        PlantCard(plant: plant)
        PlantCard(plant: plant)
    }
    .padding()
}
