//
//  CareTaskWidget.swift
//  FloraScanWidget
//
//  Created by José Luis Corral López on 12/5/26.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct CareTaskEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskSnapshot]
    let totalCount: Int

    static let placeholder = CareTaskEntry(
        date: .now,
        tasks: [
            TaskSnapshot(plantName: "Pothos", careTypeRaw: "watering", isUrgent: false),
            TaskSnapshot(plantName: "Monstera", careTypeRaw: "fertilizing", isUrgent: false),
            TaskSnapshot(plantName: "Olive tree", careTypeRaw: "pruning", isUrgent: true),
        ],
        totalCount: 3
    )

    static let empty = CareTaskEntry(date: .now, tasks: [], totalCount: 0)
}

struct TaskSnapshot: Identifiable, Sendable {
    let id = UUID()
    let plantName: String
    let careTypeRaw: String
    let isUrgent: Bool

    var careType: CareType { CareType(rawValue: careTypeRaw) ?? .watering }
}

// MARK: - Timeline Provider

struct CareTaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> CareTaskEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CareTaskEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CareTaskEntry>) -> Void) {
        let entry = fetchEntry()

        // Reload at midnight or in 1 hour, whichever is sooner
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!)
        let oneHour = Date.now.addingTimeInterval(3600)
        let nextRefresh = min(midnight, oneHour)

        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func fetchEntry() -> CareTaskEntry {
        guard let container = try? SharedModelContainer.create() else {
            return .empty
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<CareTask>(sortBy: [SortDescriptor(\.nextDueAt)])

        guard let allTasks = try? context.fetch(descriptor) else {
            return .empty
        }

        let calendar = Calendar.current
        let todayTasks = allTasks.filter {
            calendar.isDateInToday($0.nextDueAt) || $0.nextDueAt < .now
        }

        let snapshots = todayTasks.prefix(5).map { task in
            let name = {
                let nickname = task.plant?.nickname ?? ""
                return nickname.isEmpty ? (task.plant?.commonName ?? "Plant") : nickname
            }()
            let urgent = task.nextDueAt < calendar.startOfDay(for: .now)
            return TaskSnapshot(plantName: name, careTypeRaw: task.typeRaw, isUrgent: urgent)
        }

        return CareTaskEntry(date: .now, tasks: Array(snapshots), totalCount: todayTasks.count)
    }
}

// MARK: - Widget Definition

struct CareTaskWidget: Widget {
    let kind = "CareTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CareTaskProvider()) { entry in
            CareTaskWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(hex: "#F5F1E8")
                }
        }
        .configurationDisplayName("Today's Care")
        .description("See your plant care tasks for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Views

struct CareTaskWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CareTaskEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small

private struct SmallWidgetView: View {
    let entry: CareTaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "#0E5C3F"))
                Text("FloraScan")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "#1A1612"))
            }

            Spacer()

            if entry.totalCount == 0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: "#2F8262"))
                Text("All done!")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#1A1612"))
            } else {
                Text("\(entry.totalCount)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#0E5C3F"))
                Text(entry.totalCount == 1 ? "care task today" : "care tasks today")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "#4A4640"))
            }

            if let first = entry.tasks.first {
                HStack(spacing: 4) {
                    Image(systemName: first.careType.symbolName)
                        .font(.system(size: 10))
                    Text(first.plantName)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(Color(hex: "#7A766F"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Medium

private struct MediumWidgetView: View {
    let entry: CareTaskEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: summary
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#0E5C3F"))
                    Text("Today")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "#1A1612"))
                }

                Spacer()

                if entry.totalCount == 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: "#2F8262"))
                    Text("All caught up!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#1A1612"))
                } else {
                    Text("\(entry.totalCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#0E5C3F"))
                    Text(entry.totalCount == 1 ? "task" : "tasks")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "#4A4640"))
                }
            }
            .frame(maxHeight: .infinity, alignment: .leading)

            if !entry.tasks.isEmpty {
                // Right: task list
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.tasks.prefix(4)) { task in
                        WidgetTaskRow(task: task)
                    }

                    if entry.totalCount > 4 {
                        Text("+\(entry.totalCount - 4) more")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "#7A766F"))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}

private struct WidgetTaskRow: View {
    let task: TaskSnapshot

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: task.careType.symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(widgetColor(for: task.careType))
                .frame(width: 24, height: 24)
                .background(widgetColor(for: task.careType).opacity(0.13), in: .rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 1) {
                Text(task.plantName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#1A1612"))
                    .lineLimit(1)
                Text(task.careType.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#7A766F"))
            }

            Spacer()

            if task.isUrgent {
                Text("!")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "#A24A3A"))
                    .frame(width: 16, height: 16)
                    .background(Color(hex: "#F2C5BD"), in: Circle())
            }
        }
    }
}

// MARK: - Widget color helper (no UIColor dynamic in widgets)

private func widgetColor(for type: CareType) -> Color {
    switch type {
    case .watering: Color(hex: "#4E78B0")
    case .pruning: Color(hex: "#6F5734")
    case .fertilizing: Color(hex: "#6F4F90")
    case .repotting: Color(hex: "#9C5635")
    case .rotation: Color(hex: "#0E5C3F")
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    CareTaskWidget()
} timeline: {
    CareTaskEntry.placeholder
    CareTaskEntry.empty
}

#Preview("Medium", as: .systemMedium) {
    CareTaskWidget()
} timeline: {
    CareTaskEntry.placeholder
    CareTaskEntry.empty
}
