//
//  LightLevel.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation

nonisolated enum LightLevel: String, Codable, CaseIterable, Sendable {
    case low, medium, bright, direct

    var modifier: Double {
        switch self {
        case .low: 1.3
        case .medium: 1.0
        case .bright: 0.85
        case .direct: 0.7
        }
    }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .bright: "Bright"
        case .direct: "Direct"
        }
    }
}
