//
//  HistoryStrip.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct HistoryStrip: View {
    let photos: [PlantPhoto]

    var body: some View {
        if !photos.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text("PHOTOS")
                    .font(.fsMonoCap)
                    .tracking(0.4)
                    .foregroundStyle(Palette.Dynamic.textTertiary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s2) {
                        ForEach(photos.sorted { $0.capturedAt > $1.capturedAt }) { photo in
                            ZStack(alignment: .bottomLeading) {
                                AsyncPlantImage(fileName: photo.fileName)
                                    .frame(width: 76, height: 76)
                                    .clipShape(.rect(cornerRadius: Radius.chip))

                                Text(photo.capturedAt, style: .date)
                                    .font(.fsCaption2)
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    .padding(.horizontal, 5)
                                    .padding(.bottom, 4)
                            }
                            .accessibilityLabel(
                                "Photo from \(photo.capturedAt.formatted(date: .abbreviated, time: .omitted))"
                            )
                        }
                    }
                }
            }
        }
    }
}
