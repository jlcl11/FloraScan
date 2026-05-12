//
//  PlantDetailView.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import SwiftData

struct PlantDetailView: View {
    @Environment(\.modelContext) private var context
    let plant: Plant

    @State private var showActionFeedback: CareType?
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var notes: String = ""
    @State private var noteSaveTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)

                contentSection
                    .padding(.top, -Spacing.s5)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
        .onAppear { notes = plant.notes }
        .onDisappear {
            noteSaveTask?.cancel()
            if plant.notes != notes {
                plant.notes = notes
                context.safeSave()
            }
        }
        .task {
            await PlantEnrichmentService.enrichIfNeeded(plant: plant, context: context)
        }
        .sheet(isPresented: $showEditSheet) {
            EditPlantSheet(plant: plant)
        }
        .alert("Delete plant", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                CareReminderScheduler.cancelAll(for: plant)
                context.delete(plant)
                context.safeSave()
            }
        } message: {
            Text("All data, photos and reminders for this plant will be deleted. This action cannot be undone.")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            BackButton()
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: Spacing.s1) {
                plantMenu
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            AsyncPlantImage(
                fileName: (plant.photos.first(where: \.isPrimary) ?? plant.photos.first)?.fileName
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            // Gradiente de legibilidad
            LinearGradient(
                colors: [.black.opacity(0.35), .clear, .black.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Bloque tipográfico bottom
            VStack(alignment: .leading, spacing: 2) {
                if let family = plant.familyName {
                    Text("FAMILIA · \(family.uppercased())")
                        .font(.fsMonoCap)
                        .tracking(0.4)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Text(plant.nickname.isEmpty ? plant.commonName : plant.nickname)
                    .font(.fsLargeTitle)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

                Text(plant.scientificName)
                    .font(.custom("NewYorkItalic", size: 18, relativeTo: .body))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.s5)
            .padding(.bottom, Spacing.s5 + Spacing.s4)
        }
    }

    // MARK: - Content card

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            healthRow
            careGrid
            quickActionsRow
            if let desc = plant.descriptionExtract, !desc.isEmpty {
                infoSection(desc)
            }
            HistoryStrip(photos: plant.photos)
            notesSection
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.top, Spacing.s5)
        .padding(.bottom, Spacing.s10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Palette.Dynamic.surfaceApp,
            in: UnevenRoundedRectangle(cornerRadii: .init(
                topLeading: Radius.sheet,
                bottomLeading: 0,
                bottomTrailing: 0,
                topTrailing: Radius.sheet
            ))
        )
    }

    // MARK: - Health row

    private var healthRow: some View {
        HStack(alignment: .center, spacing: Spacing.s4) {
            HealthRing(
                value: plant.healthScore,
                size: 56,
                stroke: 4,
                label: "\(Int(plant.healthScore * 100))"
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(healthStatusLabel)
                    .font(.fsHeadline)
                    .foregroundStyle(Palette.Dynamic.textPrimary)
                Text("Added \(plant.createdAt, format: .relative(presentation: .named))")
                    .font(.fsFootnote)
                    .foregroundStyle(Palette.Dynamic.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if !plant.locationLabel.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.fsCaption1)
                        Text(plant.locationLabel)
                            .font(.fsCaption1)
                    }
                    .foregroundStyle(Palette.Dynamic.textSecondary)
                }
                Text(plant.acquisitionDate, style: .date)
                    .font(.fsCaption1)
                    .foregroundStyle(Palette.Dynamic.textTertiary)
            }
        }
    }

    private var healthStatusLabel: String {
        switch plant.healthScore {
        case 0.7...: "Excellent health"
        case 0.4..<0.7: "Moderate attention"
        default: "Needs help"
        }
    }

    // MARK: - Care grid

    private var careGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text("UPCOMING CARE")
                .font(.fsMonoCap)
                .tracking(0.4)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            let sorted = plant.careTasks.sorted { $0.nextDueAt < $1.nextDueAt }
            if sorted.isEmpty {
                Text("No care tasks scheduled")
                    .font(.fsCallout)
                    .foregroundStyle(Palette.Dynamic.textTertiary)
            } else {
                let cols = [
                    GridItem(.flexible(), spacing: Spacing.s2),
                    GridItem(.flexible(), spacing: Spacing.s2)
                ]
                LazyVGrid(columns: cols, spacing: Spacing.s2) {
                    ForEach(sorted) { task in
                        CareCard(careTask: task)
                    }
                }
            }
        }
    }

    // MARK: - Quick actions

    private var quickActionsRow: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text("MARK AS DONE")
                .font(.fsMonoCap)
                .tracking(0.4)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            HStack(spacing: Spacing.s2) {
                careActionButton(.watering, label: "Watered")
                careActionButton(.pruning, label: "Pruned")
                careActionButton(.fertilizing, label: "Fertilized")
            }
        }
    }

    private func careActionButton(_ type: CareType, label: String) -> some View {
        Button { markAsDone(type) } label: {
            VStack(spacing: Spacing.s1) {
                Image(systemName: type.symbolName)
                    .font(.fsCallout)
                    .foregroundStyle(type.color)
                    .symbolEffect(.bounce, value: showActionFeedback == type)
                Text(label)
                    .font(.fsCaption2)
                    .foregroundStyle(Palette.Dynamic.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s3)
            .background(type.color.opacity(0.12), in: .rect(cornerRadius: Radius.cardSmall))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info (Wikipedia description)

    @State private var infoExpanded = false

    private func infoSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("ABOUT")
                .font(.fsMonoCap)
                .tracking(0.4)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            Text(text)
                .font(.fsBody)
                .foregroundStyle(Palette.Dynamic.textSecondary)
                .lineLimit(infoExpanded ? nil : 4)

            if text.count > 200 {
                Button(infoExpanded ? "Show less" : "Show more") {
                    withAnimation(.smooth) { infoExpanded.toggle() }
                }
                .font(.fsCaption1)
                .foregroundStyle(Palette.leaf700)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("NOTES")
                .font(.fsMonoCap)
                .tracking(0.4)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            TextEditor(text: $notes)
                .scrollContentBackground(.hidden)
                .font(.fsBody)
                .padding(Spacing.s3)
                .frame(minHeight: 100)
                .background(Palette.Dynamic.surfaceTinted, in: .rect(cornerRadius: Radius.cardSmall))
                .onChange(of: notes) { _, newValue in
                    plant.notes = newValue
                    // Save is debounced via task cancellation
                    noteSaveTask?.cancel()
                    noteSaveTask = Task {
                        try? await Task.sleep(for: .seconds(1))
                        context.safeSave()
                    }
                }
        }
    }

    // MARK: - Menu

    private var plantMenu: some View {
        Menu {
            Button {
                showEditSheet = true
            } label: { Label("Edit", systemImage: "pencil") }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: { Label("Delete", systemImage: "trash") }
        } label: {
            Image(systemName: "ellipsis")
                .font(.fsCallout)
                .frame(width: 36, height: 36)
        }
        .glassed(in: .circle, interactive: true)
    }

    // MARK: - Actions

    private func markAsDone(_ type: CareType) {
        showActionFeedback = type
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let completedTask = plant.careTasks.first(where: { $0.type == type })
        if let completedTask {
            CareScheduler.recalculateAfterCompletion(task: completedTask, plant: plant)
        }

        context.safeSave()

        Task {
            if let completedTask {
                await CareReminderScheduler.schedule(task: completedTask)
            }
            try? await Task.sleep(for: .seconds(1))
            showActionFeedback = nil
        }
    }
}

// MARK: - Back button

private struct BackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.fsHeadline)
                .frame(width: 36, height: 36)
        }
        .glassed(in: .circle, interactive: true)
    }
}

#Preview {
    let plant = Plant(scientificName: "Olea europaea", commonName: "Olivo", nickname: "Mi olivo")
    plant.healthScore = 0.92
    plant.locationLabel = "Terraza"
    plant.wateringIntervalDays = 7
    return NavigationStack {
        PlantDetailView(plant: plant)
    }
    .modelContainer(for: Plant.self, inMemory: true)
}
