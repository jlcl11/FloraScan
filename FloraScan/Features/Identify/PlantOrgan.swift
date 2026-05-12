//
//  PlantOrgan.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

nonisolated enum PlantOrgan: String, CaseIterable, Sendable {
    case auto, leaf, flower, fruit, bark

    var displayName: String {
        switch self {
        case .auto: "Auto"
        case .leaf: "Leaf"
        case .flower: "Flower"
        case .fruit: "Fruit"
        case .bark: "Bark"
        }
    }

    var symbolName: String {
        switch self {
        case .auto: "wand.and.stars"
        case .leaf: "leaf.fill"
        case .flower: "camera.macro"
        case .fruit: "circle.grid.2x1.fill"
        case .bark: "tree.fill"
        }
    }
}
