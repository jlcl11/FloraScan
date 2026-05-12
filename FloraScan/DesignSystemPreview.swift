//
//  DesignSystemPreview.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//
//  Reference preview showing all design system tokens and components.
//  Open in Xcode Canvas to QA the visual system.
//

import SwiftUI

struct DesignSystemPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                paletteSection
                typographySection
                buttonsSection
                chipsSection
                healthRingsSection
                cardsSection
                spacingSection
            }
            .padding(Spacing.s5)
        }
        .background(Palette.Dynamic.surfaceApp)
    }

    // MARK: - Palette

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            sectionHeader("PALETTE")

            swatchGroup("Brand — Leaf", colors: [
                ("leaf900", Palette.leaf900),
                ("leaf700", Palette.leaf700),
                ("leaf500", Palette.leaf500),
                ("leaf300", Palette.leaf300),
                ("leaf100", Palette.leaf100),
            ])

            swatchGroup("Brand — Amber", colors: [
                ("amber700", Palette.amber700),
                ("amber500", Palette.amber500),
                ("amber200", Palette.amber200),
            ])

            swatchGroup("Brand — Clay", colors: [
                ("clay700", Palette.clay700),
                ("clay500", Palette.clay500),
                ("clay200", Palette.clay200),
            ])

            swatchGroup("Care", colors: [
                ("water", Palette.careWater),
                ("prune", Palette.carePrune),
                ("fertilize", Palette.careFertilize),
                ("repot", Palette.careRepot),
            ])

            swatchGroup("Surface", colors: [
                ("app", Palette.surfaceApp),
                ("card", Palette.surfaceCard),
                ("elev", Palette.surfaceElev),
                ("tinted", Palette.surfaceTinted),
            ])

            swatchGroup("Text", colors: [
                ("primary", Palette.textPrimary),
                ("secondary", Palette.textSecondary),
                ("tertiary", Palette.textTertiary),
                ("quaternary", Palette.textQuaternary),
            ])
        }
    }

    private func swatchGroup(_ title: String, colors: [(String, Color)]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(title)
                .font(.fsFootnote)
                .foregroundStyle(Palette.textSecondary)

            HStack(spacing: Spacing.s2) {
                ForEach(colors, id: \.0) { name, color in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .frame(width: 48, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Palette.borderSubtle, lineWidth: 1)
                            )
                        Text(name)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(Palette.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Typography

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            sectionHeader("TYPOGRAPHY")

            Group {
                Text("Display 44pt").font(.fsDisplay)
                Text("Large Title 34pt").font(.fsLargeTitle)
                Text("Title 1 — 28pt").font(.fsTitle1)
                Text("Title 2 — 22pt").font(.fsTitle2)
                Text("Title 3 — 20pt").font(.fsTitle3)
                Text("Headline — 17pt").font(.fsHeadline)
                Text("Body — 17pt regular").font(.fsBody)
                Text("Callout — 16pt").font(.fsCallout)
                Text("Subhead — 15pt").font(.fsSubhead)
                Text("Footnote — 13pt").font(.fsFootnote)
            }
            .foregroundStyle(Palette.Dynamic.textPrimary)

            Group {
                Text("Caption 1 — 12pt").font(.fsCaption1)
                Text("Caption 2 — 11pt").font(.fsCaption2)
                Text("MONO CAP — 11PT")
                    .font(.fsMonoCap)
                    .tracking(0.4)
                    .textCase(.uppercase)
            }
            .foregroundStyle(Palette.Dynamic.textSecondary)

            Divider()

            Text("Olea europaea").font(.fsSciSmall)
                .foregroundStyle(Palette.Dynamic.textSecondary)
            Text("Olea europaea").font(.fsSciDefault)
                .foregroundStyle(Palette.Dynamic.textSecondary)
            Text("Olea europaea").font(.fsSciLarge)
                .foregroundStyle(Palette.Dynamic.textSecondary)
            Text("Olea europaea").font(.fsSciHero)
                .foregroundStyle(Palette.Dynamic.textSecondary)
        }
    }

    // MARK: - Buttons

    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            sectionHeader("BUTTONS")

            Text("Prominent").fsButtonProminent()
            Text("Glass").fsButtonGlass()
            Text("Plain").fsButtonPlain()
            Text("Destructive").fsButtonDestructive()
        }
    }

    // MARK: - Chips

    private var chipsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            sectionHeader("CHIPS")

            HStack(spacing: Spacing.s2) {
                Text("Neutral").fsChip()
                Text("Glass").fsChipGlass()
                Text("Leaf").fsChipLeaf()
            }
        }
    }

    // MARK: - HealthRings

    private var healthRingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            sectionHeader("HEALTH RINGS")

            HStack(spacing: Spacing.s4) {
                VStack(spacing: 4) {
                    HealthRing(value: 0.92, size: 28, stroke: 2.5)
                    Text("28pt").font(.fsCaption2).foregroundStyle(.secondary)
                }
                VStack(spacing: 4) {
                    HealthRing(value: 0.92, size: 48, stroke: 3, label: "92")
                    Text("48pt OK").font(.fsCaption2).foregroundStyle(.secondary)
                }
                VStack(spacing: 4) {
                    HealthRing(value: 0.55, size: 56, stroke: 3.5, label: "55")
                    Text("56pt Warn").font(.fsCaption2).foregroundStyle(.secondary)
                }
                VStack(spacing: 4) {
                    HealthRing(value: 0.25, size: 56, stroke: 3.5, label: "25")
                    Text("56pt Crit").font(.fsCaption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Cards

    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            sectionHeader("CARDS")

            FSCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Olive tree")
                        .font(.fsHeadline)
                        .foregroundStyle(Palette.Dynamic.textPrimary)
                    Text("Olea europaea")
                        .font(.fsSciDefault)
                        .foregroundStyle(Palette.Dynamic.textSecondary)
                    Text("Next watering in 4 days")
                        .font(.fsCaption1)
                        .foregroundStyle(Palette.Dynamic.textTertiary)
                }
            }
        }
    }

    // MARK: - Spacing

    private var spacingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            sectionHeader("SPACING")

            HStack(alignment: .bottom, spacing: Spacing.s2) {
                spacingBar("s1", Spacing.s1)
                spacingBar("s2", Spacing.s2)
                spacingBar("s3", Spacing.s3)
                spacingBar("s4", Spacing.s4)
                spacingBar("s5", Spacing.s5)
                spacingBar("s6", Spacing.s6)
                spacingBar("s7", Spacing.s7)
                spacingBar("s8", Spacing.s8)
            }
        }
    }

    private func spacingBar(_ label: String, _ value: CGFloat) -> some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Palette.leaf500)
                .frame(width: 24, height: value)
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.textTertiary)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.fsMonoCap)
            .tracking(0.4)
            .textCase(.uppercase)
            .foregroundStyle(Palette.textTertiary)
            .padding(.bottom, Spacing.s1)
    }
}

#Preview("Design System") {
    DesignSystemPreview()
}
