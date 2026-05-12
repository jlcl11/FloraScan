//
//  CareTask.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation
import SwiftData

@Model
final class CareTask {
    @Attribute(.unique) var id: UUID = UUID()
    var typeRaw: String = "watering"
    var intervalDays: Int = 7
    var lastDoneAt: Date?
    var nextDueAt: Date = Date()
    var notificationID: String?
    var plant: Plant?

    var type: CareType {
        get { CareType(rawValue: typeRaw) ?? .watering }
        set { typeRaw = newValue.rawValue }
    }

    init(type: CareType, intervalDays: Int, nextDueAt: Date) {
        self.typeRaw = type.rawValue
        self.intervalDays = intervalDays
        self.nextDueAt = nextDueAt
    }
}
