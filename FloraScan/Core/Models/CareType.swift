//
//  CareType.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

nonisolated enum CareType: String, Codable, CaseIterable, Sendable {
    case watering, pruning, fertilizing, repotting, rotation

    var symbolName: String {
        switch self {
        case .watering: "drop.fill"
        case .pruning: "scissors"
        case .fertilizing: "sparkles.rectangle.stack.fill"
        case .repotting: "arrow.up.bin.fill"
        case .rotation: "arrow.triangle.2.circlepath"
        }
    }

    var displayName: String {
        switch self {
        case .watering: "Watering"
        case .pruning: "Pruning"
        case .fertilizing: "Fertilizing"
        case .repotting: "Repotting"
        case .rotation: "Rotation"
        }
    }

    var color: Color {
        switch self {
        case .watering: Palette.Dynamic.careWater
        case .pruning: Palette.Dynamic.carePrune
        case .fertilizing: Palette.Dynamic.careFertilize
        case .repotting: Palette.Dynamic.careRepot
        case .rotation: Palette.Dynamic.primary
        }
    }
}
