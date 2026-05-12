//
//  TaskRow.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct TaskRow: View {
    let careTask: CareTask
    let onComplete: () -> Void

    @State private var bounceTrigger = false

    private var isUrgent: Bool {
        Calendar.current.isDateInToday(careTask.nextDueAt) || careTask.nextDueAt < .now
    }

    var body: some View {
        HStack(spacing: Spacing.s3) {
            // Care type icon
            Image(systemName: careTask.type.symbolName)
                .font(.fsCallout)
                .foregroundStyle(careTask.type.color)
                .frame(width: 40, height: 40)
                .background(careTask.type.color.opacity(0.13), in: .rect(cornerRadius: 12))

            // Plant info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.s2) {
                    Text(careTask.plant?.nickname ?? careTask.plant?.commonName ?? "")
                        .font(.fsSubhead)
                        .foregroundStyle(Palette.Dynamic.textPrimary)

                    if isUrgent {
                        Text("Urgent")
                            .font(.fsCaption2)
                            .foregroundStyle(Palette.clay700)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Palette.clay200, in: Capsule())
                    }
                }

                HStack(spacing: 6) {
                    Text(careTask.type.displayName)
                        .font(.fsCaption1)
                        .foregroundStyle(Palette.Dynamic.textSecondary)

                    if let plant = careTask.plant {
                        Text(plant.scientificName)
                            .font(.fsSciSmall)
                            .foregroundStyle(Palette.Dynamic.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Checkbox
            Button {
                bounceTrigger.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onComplete()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.fsTitle2)
                    .foregroundStyle(Palette.statusOk)
                    .symbolEffect(.bounce, value: bounceTrigger)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.s3)
        .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardSmall))
        .fsShadow(1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(taskAccessibilityLabel)
        .accessibilityHint("Double tap to mark as done")
    }

    private var taskAccessibilityLabel: String {
        let nickname = careTask.plant?.nickname ?? ""
        let name = nickname.isEmpty ? (careTask.plant?.commonName ?? "") : nickname
        let careTypeName = careTask.type.displayName
        var label = "\(careTypeName) \(name)"
        if isUrgent { label += ", urgent" }
        return label
    }
}
