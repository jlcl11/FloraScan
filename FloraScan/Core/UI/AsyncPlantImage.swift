//
//  AsyncPlantImage.swift
//  FloraScan
//
//  Created by José Luis Corral López on 29/4/26.
//

import SwiftUI

/// Loads a plant photo off the main thread with a placeholder.
struct AsyncPlantImage: View {
    let fileName: String?
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                ZStack {
                    Color(Palette.leaf100).opacity(0.3)
                    Image(systemName: "leaf.fill")
                        .font(.fsTitle3)
                        .foregroundStyle(Palette.leaf300)
                }
            }
        }
        .task(id: fileName) {
            guard let fileName, !fileName.isEmpty else { return }
            image = await loadImage(fileName)
        }
    }

    private func loadImage(_ name: String) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            ImageStore.load(fileName: name)
        }.value
    }
}
