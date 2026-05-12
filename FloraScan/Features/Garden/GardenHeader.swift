//
//  GardenHeader.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct GardenHeader: View {
    let plantCount: Int
    let thirstyCount: Int

    private var dateLabel: String {
        Date.now.formatted(.dateTime.day().month(.abbreviated))
            .uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(dateLabel)
                .font(.fsMonoCap)
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            Text("My garden")
                .font(.fsLargeTitle)
                .foregroundStyle(Palette.Dynamic.textPrimary)

            HStack(spacing: 0) {
                Text("\(plantCount)")
                    .contentTransition(.numericText())
                    .animation(.smooth, value: plantCount)
                Text(plantCount == 1 ? " plant" : " plants")

                if thirstyCount > 0 {
                    Text(" · ")
                    Text("\(thirstyCount)")
                        .contentTransition(.numericText())
                        .animation(.smooth, value: thirstyCount)
                    Text(thirstyCount == 1 ? " thirsty" : " thirsty")
                }
            }
            .font(.fsCallout)
            .foregroundStyle(Palette.Dynamic.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.s5)
        .padding(.top, Spacing.s2)
        .padding(.bottom, Spacing.s3)
    }
}

#Preview {
    VStack {
        GardenHeader(plantCount: 6, thirstyCount: 1)
        GardenHeader(plantCount: 0, thirstyCount: 0)
    }
    .background(Palette.Dynamic.surfaceApp)
}
