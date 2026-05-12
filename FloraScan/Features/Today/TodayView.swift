//
//  TodayView.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CareTask.nextDueAt) private var allTasks: [CareTask]

    private var todayTasks: [CareTask] {
        allTasks.filter { Calendar.current.isDateInToday($0.nextDueAt) || $0.nextDueAt < .now }
    }

    private var weekTasks: [CareTask] {
        let cal = Calendar.current
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: .now) ?? Date().addingTimeInterval(7 * 86400)
        return allTasks.filter {
            !cal.isDateInToday($0.nextDueAt)
            && $0.nextDueAt > .now
            && $0.nextDueAt <= endOfWeek
        }
    }

    private var upcomingTasks: [CareTask] {
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? Date().addingTimeInterval(7 * 86400)
        return Array(allTasks.filter { $0.nextDueAt > endOfWeek }.prefix(20))
    }

    private var todayCount: Int { todayTasks.count }

    var body: some View {
        Group {
            if allTasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .navigationTitle("Today")
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No tasks", systemImage: "checkmark.circle")
        } description: {
            Text("Add plants to see your pending care tasks.")
        }
    }

    // MARK: - Task list

    private var taskList: some View {
        List {
            // Header (no swipe)
            Section {
                headerView
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            if !todayTasks.isEmpty {
                Section {
                    ForEach(todayTasks) { task in
                        taskRow(task: task, showRelativeDate: false)
                            .swipeActions(edge: .trailing, allowsFullSwipe: canComplete(task)) {
                                if canComplete(task) {
                                    Button {
                                        completeTask(task)
                                    } label: {
                                        Label("Done", systemImage: "checkmark")
                                    }
                                    .tint(Palette.statusOk)
                                }
                            }
                    }
                } header: {
                    Text("TODAY")
                        .font(.fsMonoCap)
                        .tracking(0.4)
                        .foregroundStyle(Palette.Dynamic.textTertiary)
                }
            }

            if !weekTasks.isEmpty {
                Section {
                    ForEach(weekTasks) { task in
                        taskRow(task: task, showRelativeDate: true)
                            .swipeActions(edge: .trailing, allowsFullSwipe: canComplete(task)) {
                                if canComplete(task) {
                                    Button {
                                        completeTask(task)
                                    } label: {
                                        Label("Done", systemImage: "checkmark")
                                    }
                                    .tint(Palette.statusOk)
                                }
                            }
                    }
                } header: {
                    Text("THIS WEEK")
                        .font(.fsMonoCap)
                        .tracking(0.4)
                        .foregroundStyle(Palette.Dynamic.textTertiary)
                }
            }

            if !upcomingTasks.isEmpty {
                Section {
                    ForEach(upcomingTasks) { task in
                        taskRow(task: task, showRelativeDate: true)
                            .swipeActions(edge: .trailing, allowsFullSwipe: canComplete(task)) {
                                if canComplete(task) {
                                    Button {
                                        completeTask(task)
                                    } label: {
                                        Label("Done", systemImage: "checkmark")
                                    }
                                    .tint(Palette.statusOk)
                                }
                            }
                    }
                } header: {
                    Text("UPCOMING")
                        .font(.fsMonoCap)
                        .tracking(0.4)
                        .foregroundStyle(Palette.Dynamic.textTertiary)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                .font(.fsMonoCap)
                .tracking(0.4)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            HStack(spacing: 4) {
                Text("\(todayCount)")
                    .contentTransition(.numericText())
                Text(todayCount == 1 ? "care task due" : "care tasks due")
            }
            .font(.fsCallout)
            .foregroundStyle(Palette.Dynamic.textSecondary)
            .animation(.smooth, value: todayCount)
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.vertical, Spacing.s3)
    }

    // MARK: - Task Row

    private func taskRow(task: CareTask, showRelativeDate: Bool) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: task.type.symbolName)
                .font(.fsCallout)
                .foregroundStyle(task.type.color)
                .frame(width: 36, height: 36)
                .background(task.type.color.opacity(0.13), in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.s2) {
                    Text(plantName(for: task))
                        .font(.fsSubhead)
                        .foregroundStyle(Palette.Dynamic.textPrimary)

                    if !showRelativeDate && isUrgent(task) {
                        Text("Urgent")
                            .font(.fsCaption2)
                            .foregroundStyle(Palette.clay700)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Palette.clay200, in: Capsule())
                    }
                }
                Text(task.type.displayName)
                    .font(.fsCaption1)
                    .foregroundStyle(Palette.Dynamic.textSecondary)
            }

            Spacer()

            if showRelativeDate {
                Text(task.nextDueAt, format: .relative(presentation: .named))
                    .font(.fsCaption1)
                    .foregroundStyle(Palette.Dynamic.textTertiary)
            } else if canComplete(task) {
                Button {
                    completeTask(task)
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.fsTitle3)
                        .foregroundStyle(Palette.statusOk)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.fsTitle3)
                    .foregroundStyle(Palette.statusOk.opacity(0.4))
            }
        }
        .padding(.vertical, Spacing.s1)
    }

    // MARK: - Helpers

    private func plantName(for task: CareTask) -> String {
        let nickname = task.plant?.nickname ?? ""
        return nickname.isEmpty ? (task.plant?.commonName ?? "") : nickname
    }

    private func isUrgent(_ task: CareTask) -> Bool {
        Calendar.current.isDateInToday(task.nextDueAt) || task.nextDueAt < .now
    }

    // MARK: - Complete

    private func canComplete(_ task: CareTask) -> Bool {
        // Can only complete if due today or overdue
        guard task.nextDueAt <= Date.now || Calendar.current.isDateInToday(task.nextDueAt) else {
            return false
        }
        // Can't complete if already done today
        if let lastDone = task.lastDoneAt, Calendar.current.isDateInToday(lastDone) {
            return false
        }
        return true
    }

    private func completeTask(_ task: CareTask) {
        guard canComplete(task), let plant = task.plant else { return }
        withAnimation(.smooth) {
            CareScheduler.recalculateAfterCompletion(task: task, plant: plant)
            context.safeSave()
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task {
            await CareReminderScheduler.schedule(task: task)
        }
    }
}

#Preview {
    NavigationStack { TodayView() }
        .modelContainer(for: Plant.self, inMemory: true)
}
