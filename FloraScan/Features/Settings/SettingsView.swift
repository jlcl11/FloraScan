//
//  SettingsView.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import SwiftData
import os

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                identificationSection
                aboutSection
                dataSection
                versionSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Delete all data", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete all", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("All your plants, photos and reminders will be deleted. This action cannot be undone.")
            }
        }
    }

    // MARK: - Sections

    private var identificationSection: some View {
        Section {
            LabeledContent("Primary engine") {
                Text("Pl@ntNet API")
                    .foregroundStyle(Palette.Dynamic.textSecondary)
            }
            LabeledContent("On-device engine") {
                Text("Core ML (Vision)")
                    .foregroundStyle(Palette.Dynamic.textSecondary)
            }
            LabeledContent("Strategy") {
                Text("Parallel (API + local)")
                    .foregroundStyle(Palette.Dynamic.textSecondary)
            }
        } header: {
            Text("Identification")
        }
    }

    private var aboutSection: some View {
        Section {
            linkRow("Pl@ntNet", icon: "leaf.fill", urlString: "https://my.plantnet.org")
            linkRow("Perenual API", icon: "sparkles", urlString: "https://perenual.com")
            linkRow("Wikipedia", icon: "book.fill", urlString: "https://es.wikipedia.org")
        } header: {
            Text("About")
        } footer: {
            Text("FloraScan uses data from Pl@ntNet, Perenual and Wikipedia to identify plants and suggest care.")
        }
    }

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete all my data", systemImage: "trash")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Deletes all plants, photos and reminders from this device.")
        }
    }

    private var versionSection: some View {
        Section {
            LabeledContent("Version") {
                Text("1.0.0 MVP")
                    .foregroundStyle(Palette.Dynamic.textTertiary)
            }
            LabeledContent("Platform") {
                Text("iOS 26 · Swift 6.2")
                    .foregroundStyle(Palette.Dynamic.textTertiary)
            }
        }
    }

    // MARK: - Helpers

    private func linkRow(_ title: String, icon: String, urlString: String) -> some View {
        Group {
            if let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack {
                        Label(title, systemImage: icon)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.fsCaption2)
                            .foregroundStyle(Palette.Dynamic.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func deleteAllData() {
        do {
            try context.delete(model: Plant.self)
            try context.delete(model: PlantPhoto.self)
            try context.delete(model: CareTask.self)
            try context.save()

            // Clean up photo files
            ImageStore.deleteAll()

            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        } catch {
            // Non-fatal: models may already be empty
            Logger.persistence.error("deleteAllData failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Plant.self, inMemory: true)
}
