//
//  GardenView.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import SwiftData

struct GardenView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Plant.createdAt, order: .reverse) private var plants: [Plant]
    @State private var searchText = ""
    @State private var showAddFlow = false
    @State private var showShareSheet = false
    @State private var showSettings = false
    @State private var importAlert: ImportAlert?
    @State private var plantToEdit: Plant?
    @State private var plantToDelete: Plant?
    @State private var showDeleteAlert = false
    @FocusState private var isSearchFocused: Bool
    @Namespace private var heroNS

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        if dynamicTypeSize > .xLarge {
            // Collapse to 1 column for accessibility sizes
            [GridItem(.flexible())]
        } else {
            [
                GridItem(.flexible(), spacing: Spacing.s3),
                GridItem(.flexible(), spacing: Spacing.s3)
            ]
        }
    }

    private var filtered: [Plant] {
        guard !searchText.isEmpty else { return plants }
        return plants.filter {
            $0.nickname.localizedCaseInsensitiveContains(searchText)
            || $0.commonName.localizedCaseInsensitiveContains(searchText)
            || $0.scientificName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var thirstyCount: Int {
        let calendar = Calendar.current
        return plants.filter { plant in
            plant.careTasks.contains { task in
                task.type == .watering
                && (calendar.isDateInToday(task.nextDueAt) || task.nextDueAt < Date.now)
            }
        }.count
    }

    var body: some View {
        Group {
            if plants.isEmpty {
                EmptyGardenView { showAddFlow = true }
                    .navigationTitle("My garden")
            } else {
                gardenContent
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !plants.isEmpty {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.fsCallout)
                            .frame(width: 36, height: 36)
                    }
                    .glassed(in: .circle, interactive: true)
                    .accessibilityLabel("Share garden")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.s2) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.fsCallout)
                            .frame(width: 36, height: 36)
                    }
                    .glassed(in: .circle, interactive: true)
                    .accessibilityLabel("Settings")

                    Button {
                        showAddFlow = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.fsCallout)
                            .frame(width: 36, height: 36)
                    }
                    .glassed(in: .circle, interactive: true)
                    .accessibilityLabel("Add plant")
                }
            }
        }
        .navigationDestination(for: Plant.self) { plant in
            PlantDetailView(plant: plant)
                .navigationTransition(.zoom(sourceID: plant.id, in: heroNS))
        }
        .fullScreenCover(isPresented: $showAddFlow) {
            AddPlantFlow()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showShareSheet) {
            if !plants.isEmpty {
                ShareGardenSheet(plants: plants)
            }
        }
        .onOpenURL { url in
            guard url.pathExtension == "florascan" else { return }
            do {
                let result = try GardenImporter.importFile(url: url, context: context)
                importAlert = ImportAlert(
                    title: "Garden imported",
                    message: "\(result.plantsImported) plants added to your garden."
                )
            } catch {
                importAlert = ImportAlert(
                    title: "Import error",
                    message: error.localizedDescription
                )
            }
        }
        .alert(item: $importAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
        .sheet(item: $plantToEdit) { plant in
            EditPlantSheet(plant: plant)
        }
        .alert("Delete plant", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { plantToDelete = nil }
            Button("Delete", role: .destructive) {
                if let plant = plantToDelete {
                    CareReminderScheduler.cancelAll(for: plant)
                    context.delete(plant)
                    context.safeSave()
                    plantToDelete = nil
                }
            }
        } message: {
            Text("All data, photos and reminders for this plant will be deleted.")
        }
    }

    // MARK: - Garden Content

    private var gardenContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                GardenHeader(plantCount: plants.count, thirstyCount: thirstyCount)

                searchBar
                    .padding(.horizontal, Spacing.s4)
                    .padding(.bottom, Spacing.s4)

                LazyVGrid(columns: columns, spacing: Spacing.s3) {
                    ForEach(filtered) { plant in
                        NavigationLink(value: plant) {
                            PlantCard(plant: plant)
                        }
                        .buttonStyle(.plain)
                        .matchedTransitionSource(id: plant.id, in: heroNS)
                        .contextMenu {
                            Button {
                                plantToEdit = plant
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                plantToDelete = plant
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .scrollTransition(.interactive(timingCurve: .easeOut)) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1.0 : 0.5)
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.92)
                                .blur(radius: phase.isIdentity ? 0 : 1.5)
                        }
                    }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.bottom, Spacing.s8)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.s2) {
            Image(systemName: "magnifyingglass")
                .font(.fsCallout)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            TextField("Search plant", text: $searchText)
                .font(.fsCallout)
                .foregroundStyle(Palette.Dynamic.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isSearchFocused)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.smooth(duration: 0.2)) { searchText = "" }
                    isSearchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.fsCallout)
                        .foregroundStyle(Palette.Dynamic.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, Spacing.s4)
        .background(
            Palette.Dynamic.surfaceTinted,
            in: .rect(cornerRadius: Radius.cardSmall)
        )
        .animation(.smooth(duration: 0.2), value: searchText.isEmpty)
    }
}

#Preview {
    NavigationStack { GardenView() }
        .modelContainer(for: Plant.self, inMemory: true)
}
