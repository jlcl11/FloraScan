//
//  SummaryStep.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import UIKit

struct SummaryStepView: View {
    @Bindable var state: AddPlantState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s7) {
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    Text("Ready to grow.")
                        .font(.fsTitle2)
                        .foregroundStyle(Palette.Dynamic.textPrimary)
                    Text("Review the suggested reminders.")
                        .font(.fsFootnote)
                        .foregroundStyle(Palette.Dynamic.textSecondary)
                }

                if state.isLoadingCare {
                    HStack(spacing: Spacing.s3) {
                        ProgressView()
                            .tint(Palette.leaf700)
                        Text("Fetching care data…")
                            .font(.fsCallout)
                            .foregroundStyle(Palette.Dynamic.textSecondary)
                    }
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.leaf100.opacity(0.5), in: .rect(cornerRadius: Radius.cardSmall))
                } else if let source = state.careSource {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Palette.statusOk)
                        Text("Care data from \(source)")
                            .font(.fsCaption1)
                    }
                    .foregroundStyle(Palette.Dynamic.textSecondary)
                }

                editableReminderCard(
                    icon: CareType.watering.symbolName,
                    color: Palette.Dynamic.careWater,
                    label: "Water every",
                    value: $state.wateringIntervalDays,
                    unit: "days",
                    range: 1...30,
                    subtitle: wateringSubtitle
                )

                editableReminderCard(
                    icon: CareType.fertilizing.symbolName,
                    color: Palette.Dynamic.careFertilize,
                    label: "Fertilize every",
                    value: $state.fertilizingIntervalDays,
                    unit: "days",
                    range: 7...90,
                    subtitle: fertilizingSubtitle
                )

                if !state.pruningMonths.isEmpty {
                    reminderCard(
                        icon: CareType.pruning.symbolName,
                        color: Palette.Dynamic.carePrune,
                        title: "Annual pruning",
                        subtitle: pruningSubtitle
                    )
                }

                // Plant summary preview
                if !state.scientificName.isEmpty {
                    HStack(spacing: Spacing.s3) {
                        if let data = state.photoData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(.rect(cornerRadius: 12))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.fsHeadline)
                            Text(state.scientificName)
                                .font(.fsSciSmall)
                                .foregroundStyle(Palette.Dynamic.textSecondary)
                            if !state.location.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.fsCaption2)
                                    Text(state.location)
                                        .font(.fsCaption1)
                                }
                                .foregroundStyle(Palette.Dynamic.textTertiary)
                            }
                        }
                    }
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardMedium))
                    .fsShadow(1)
                }
            }
            .padding(.horizontal, Spacing.s5)
            .padding(.vertical, Spacing.s6)
        }
    }

    private func reminderCard(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: icon)
                .font(.fsTitle3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.13), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.fsHeadline)
                Text(subtitle)
                    .font(.fsFootnote)
                    .foregroundStyle(Palette.Dynamic.textTertiary)
            }

            Spacer()
        }
        .padding(Spacing.s4)
        .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardMedium))
        .fsShadow(1)
    }

    private func editableReminderCard(
        icon: String,
        color: Color,
        label: String,
        value: Binding<Int>,
        unit: String,
        range: ClosedRange<Int>,
        subtitle: String
    ) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: icon)
                .font(.fsTitle3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.13), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.fsHeadline)
                Text(subtitle)
                    .font(.fsFootnote)
                    .foregroundStyle(Palette.Dynamic.textTertiary)
            }

            Spacer()

            Text("\(value.wrappedValue) \(unit)")
                .font(.fsHeadline)
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.smooth, value: value.wrappedValue)

            Stepper(value: value, in: range) { EmptyView() }
                .labelsHidden()
        }
        .padding(Spacing.s4)
        .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardMedium))
        .fsShadow(1)
    }

    private var displayName: String {
        if !state.nickname.isEmpty { return state.nickname }
        if !state.commonName.isEmpty { return state.commonName }
        return state.scientificName
    }

    private var fertilizingSubtitle: String {
        let interval = state.fertilizingIntervalDays
        if interval <= 7 { return "Weekly" }
        if interval <= 14 { return "Biweekly" }
        return "Monthly"
    }

    private var wateringSubtitle: String {
        let interval = state.wateringIntervalDays
        if interval <= 2 { return "Frequent" }
        if interval <= 5 { return "Moderate" }
        return "Low frequency"
    }

    private var pruningSubtitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let names = state.pruningMonths.compactMap { month -> String? in
            guard (1...12).contains(month) else { return nil }
            return formatter.monthSymbols[month - 1].capitalized
        }
        return names.joined(separator: ", ")
    }
}
