//
//  LocalCandidate.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation

nonisolated struct LocalCandidate: Equatable, Identifiable, Sendable {
    let id = UUID()
    let label: String
    let confidence: Double
}
