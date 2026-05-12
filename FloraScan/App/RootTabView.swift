//
//  RootTabView.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Query private var allTasks: [CareTask]

    private var todayBadge: Int {
        allTasks.filter {
            Calendar.current.isDateInToday($0.nextDueAt) || $0.nextDueAt < .now
        }.count
    }

    var body: some View {
        TabView {
            Tab("My garden", systemImage: "leaf.fill") {
                NavigationStack { GardenView() }
            }
            Tab("Today", systemImage: "calendar", value: "today") {
                NavigationStack { TodayView() }
            }
            .badge(todayBadge > 0 ? todayBadge : 0)
            Tab("Identify", systemImage: "camera.macro") {
                IdentifyView()
            }
        }
        .tint(Palette.primary)
    }
}

#Preview {
    RootTabView()
}
