//
//  ShareGardenSheet.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ShareGardenSheet: View {
    @Environment(\.dismiss) private var dismiss
    let plants: [Plant]

    @State private var cachedFileURL: URL?
    @State private var cachedSnapshot: Image?
    @State private var cachedUIImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.s6) {
                    // Header
                    VStack(spacing: Spacing.s2) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.fsLargeTitle)
                            .foregroundStyle(Palette.leaf700)

                        Text("Share garden")
                            .font(.fsTitle2)

                        Text("\(plants.count) plants")
                            .font(.fsCallout)
                            .foregroundStyle(Palette.Dynamic.textSecondary)
                    }
                    .padding(.top, Spacing.s6)

                    // Snapshot preview
                    if let uiImage = cachedUIImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: Radius.cardMedium))
                            .fsShadow(2)
                            .padding(.horizontal, Spacing.s5)
                    }

                    // Share buttons
                    VStack(spacing: Spacing.s3) {
                        // Share as image
                        if let snapshot = cachedSnapshot {
                            ShareLink(
                                item: snapshot,
                                preview: SharePreview(
                                    "My FloraScan garden",
                                    image: snapshot
                                )
                            ) {
                                Label("Share as image", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                            }
                            .fsButtonProminent()
                        }

                        // Share as file
                        if let fileURL = cachedFileURL {
                            ShareLink(
                                item: fileURL,
                                preview: SharePreview(
                                    "My FloraScan garden",
                                    image: Image(systemName: "leaf.fill")
                                )
                            ) {
                                Label("Share as file", systemImage: "doc.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.fsHeadline)
                            .foregroundStyle(Palette.leaf700)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 22)
                            .background(Palette.Dynamic.surfaceTinted, in: Capsule())
                        }
                    }
                    .padding(.horizontal, Spacing.s5)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                cachedFileURL = buildExportFileURL()
                let (snapshot, uiImage) = buildSnapshot()
                cachedSnapshot = snapshot
                cachedUIImage = uiImage
            }
        }
    }

    private func buildExportFileURL() -> URL? {
        let exports = plants.map { PlantExport(from: $0) }
        let gardenExport = GardenExport(plants: exports, exportedAt: .now, appVersion: "1.0")
        guard let data = try? JSONEncoder().encode(gardenExport) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MyGarden.florascan")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    private func buildSnapshot() -> (Image?, UIImage?) {
        let view = GardenSnapshotView(plants: plants)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        guard let uiImage = renderer.uiImage else { return (nil, nil) }
        return (Image(uiImage: uiImage), uiImage)
    }
}

// MARK: - Import Alert

struct ImportAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - Garden Snapshot for sharing

struct GardenSnapshotView: View {
    let plants: [Plant]

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Wordmark(color: Palette.leaf700, opacity: 1.0)
                Spacer()
                Text(plants.count == 1 ? "1 plant" : "\(plants.count) plants")
                    .font(.fsCaption1)
                    .foregroundStyle(Palette.Dynamic.textSecondary)
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(plants.prefix(6)) { plant in
                    VStack(alignment: .leading, spacing: 4) {
                        if let photo = plant.photos.first(where: \.isPrimary) ?? plant.photos.first,
                           let img = ImageStore.load(fileName: photo.fileName) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(.rect(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Palette.leaf100)
                                .frame(width: 140, height: 140)
                        }
                        Text(plant.nickname.isEmpty ? plant.commonName : plant.nickname)
                            .font(.fsCaption2)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
        .frame(width: 320)
        .background(Palette.surfaceApp)
    }
}
