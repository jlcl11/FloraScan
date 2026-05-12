//
//  CareCard.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct CareCard: View {
    let careTask: CareTask

    private var isUrgent: Bool {
        Calendar.current.isDateInToday(careTask.nextDueAt) || careTask.nextDueAt < Date.now
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Image(systemName: careTask.type.symbolName)
                .font(.fsCallout)
                .foregroundStyle(careTask.type.color)
                .symbolEffect(.wiggle.byLayer, options: .repeat(.continuous), isActive: isUrgent && careTask.type == .watering)

            Text(careTask.type.displayName)
                .font(.fsFootnote)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            Text(nextDueText)
                .font(.fsSubhead)
                .foregroundStyle(isUrgent ? Palette.clay700 : Palette.Dynamic.textPrimary)
                .lineLimit(1)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardSmall))
        .fsShadow(1)
        .accessibilityLabel("\(careTask.type.displayName): \(nextDueText)")
    }

    private var nextDueText: String {
        let calendar = Calendar.current
        let dueAt = careTask.nextDueAt
        if dueAt < Date.now || calendar.isDateInToday(dueAt) {
            return "Today"
        }
        if calendar.isDateInTomorrow(dueAt) {
            return "Tomorrow"
        }
        let days = calendar.dateComponents([.day], from: .now, to: dueAt).day ?? 0
        return "In \(days) days"
    }
}
