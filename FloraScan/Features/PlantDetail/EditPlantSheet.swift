//
//  EditPlantSheet.swift
//  FloraScan
//
//  Created by José Luis Corral López on 29/4/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditPlantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let plant: Plant

    @State private var nickname: String
    @State private var location: String
    @State private var lightLevel: LightLevel
    @State private var wateringDays: Int
    @State private var fertilizingDays: Int
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(plant: Plant) {
        self.plant = plant
        _nickname = State(initialValue: plant.nickname)
        _location = State(initialValue: plant.locationLabel)
        _lightLevel = State(initialValue: plant.lightLevelValue)
        _wateringDays = State(initialValue: plant.wateringIntervalDays)
        _fertilizingDays = State(initialValue: plant.fertilizingIntervalDays)
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                identitySection
                locationSection
                careSection
            }
            .navigationTitle("Edit plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      !data.isEmpty else { return }
                let jpeg: Data
                if let img = UIImage(data: data) {
                    let resized = img.resizedForAPI(maxDimension: 1920)
                    jpeg = resized.jpegData(compressionQuality: 0.85) ?? data
                } else {
                    jpeg = data
                }
                let fileName = "\(plant.id.uuidString).jpg"
                guard ImageStore.save(data: jpeg, fileName: fileName) else { return }
                // Remove old primary photo, insert new one
                plant.photos.removeAll(where: \.isPrimary)
                let photo = PlantPhoto(fileName: fileName, isPrimary: true)
                plant.photos.insert(photo, at: 0)
                context.safeSave()
            }
        }
    }

    // MARK: - Sections

    private var photoSection: some View {
        Section {
            HStack {
                Spacer()
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        let fileName = plant.photos.first { $0.isPrimary }?.fileName ?? plant.photos.first?.fileName
                        AsyncPlantImage(fileName: fileName)
                            .frame(width: 100, height: 100)
                            .clipShape(.rect(cornerRadius: Radius.cardSmall))

                        Image(systemName: "camera.fill")
                            .font(.fsCaption2)
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Palette.leaf700, in: .circle)
                            .offset(x: 4, y: 4)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    private var identitySection: some View {
        Section {
            HStack {
                Text("Common name")
                Spacer()
                Text(plant.commonName)
                    .foregroundStyle(Palette.Dynamic.textSecondary)
            }
            HStack {
                Text("Species")
                Spacer()
                Text(plant.scientificName)
                    .font(.fsSciSmall)
                    .foregroundStyle(Palette.Dynamic.textSecondary)
            }
            TextField("Nickname", text: $nickname, prompt: Text("My balcony olive"))
        } header: {
            Text("Identity")
        }
    }

    private var locationSection: some View {
        Section {
            TextField("Location", text: $location, prompt: Text("Balcony, living room, terrace…"))

            Picker("Light level", selection: $lightLevel) {
                ForEach(LightLevel.allCases, id: \.self) { level in
                    HStack {
                        Image(systemName: lightIcon(for: level))
                        Text(level.displayName)
                    }
                    .tag(level)
                }
            }
        } header: {
            Text("Location & light")
        } footer: {
            Text("Light level affects the recommended watering frequency.")
        }
    }

    private var careSection: some View {
        Section {
            Stepper("Water every \(wateringDays) days", value: $wateringDays, in: 1...30)
            Stepper("Fertilize every \(fertilizingDays) days", value: $fertilizingDays, in: 7...90)
        } header: {
            Text("Care")
        } footer: {
            Text("These intervals are used to calculate reminders.")
        }
    }

    // MARK: - Actions

    private func save() {
        plant.nickname = nickname
        plant.locationLabel = location
        plant.lightLevelValue = lightLevel
        plant.wateringIntervalDays = wateringDays
        plant.fertilizingIntervalDays = fertilizingDays

        for task in plant.careTasks {
            switch task.type {
            case .watering: task.intervalDays = wateringDays
            case .fertilizing: task.intervalDays = fertilizingDays
            default: break
            }
        }

        context.safeSave()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            await CareReminderScheduler.scheduleAll(for: plant)
        }

        dismiss()
    }

    // MARK: - Helpers

    private func lightIcon(for level: LightLevel) -> String {
        switch level {
        case .low: "moon.fill"
        case .medium: "cloud.sun.fill"
        case .bright: "sun.max.fill"
        case .direct: "sun.dust.fill"
        }
    }
}
