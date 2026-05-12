//
//  IdentifyStep.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct IdentifyStepView: View {
    @Bindable var state: AddPlantState
    var isIdentifying: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    Text("What's it called?")
                        .font(.fsTitle2)
                        .foregroundStyle(Palette.Dynamic.textPrimary)
                    Text(isIdentifying ? "Identifying plant…" : "Confirm or edit the identified species.")
                        .font(.fsFootnote)
                        .foregroundStyle(Palette.Dynamic.textSecondary)
                }

                // Identifying indicator
                if isIdentifying {
                    HStack(spacing: Spacing.s3) {
                        ProgressView()
                            .tint(Palette.leaf700)
                        Text("Analyzing with AI…")
                            .font(.fsCallout)
                            .foregroundStyle(Palette.Dynamic.textSecondary)
                    }
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.leaf100.opacity(0.5), in: .rect(cornerRadius: Radius.cardSmall))
                }

                // Species
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    Text("SPECIES")
                        .font(.fsMonoCap)
                        .tracking(0.4)
                        .foregroundStyle(Palette.Dynamic.textTertiary)

                    HStack {
                        TextField("Scientific name", text: $state.scientificName)
                            .font(.fsSciDefault)
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(Palette.leaf500)
                    }
                    .padding(Spacing.s4)
                    .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardSmall))
                    .fsShadow(1)

                    TextField("Common name (e.g. Olive, Pothos…)", text: $state.commonName)
                        .font(.fsBody)
                        .padding(Spacing.s4)
                        .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardSmall))
                        .fsShadow(1)
                }

                // Nickname
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    Text("NICKNAME")
                        .font(.fsMonoCap)
                        .tracking(0.4)
                        .foregroundStyle(Palette.Dynamic.textTertiary)

                    TextField("My balcony olive", text: $state.nickname)
                        .font(.fsBody)
                        .padding(Spacing.s4)
                        .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardSmall))
                        .fsShadow(1)
                }

                // Location
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    Text("LOCATION")
                        .font(.fsMonoCap)
                        .tracking(0.4)
                        .foregroundStyle(Palette.Dynamic.textTertiary)

                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Palette.primary)
                        TextField("Balcony, living room, terrace...", text: $state.location)
                            .font(.fsBody)
                    }
                    .padding(Spacing.s4)
                    .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardSmall))
                    .fsShadow(1)
                }
            }
            .padding(.horizontal, Spacing.s5)
        }
    }
}
