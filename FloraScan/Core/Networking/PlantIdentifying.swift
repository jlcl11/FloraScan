//
//  PlantIdentifying.swift
//  FloraScan
//
//  Created by José Luis Corral López on 29/4/26.
//

import Foundation

/// Abstraction for remote plant identification (PlantNet or mock).
protocol PlantIdentifying: Sendable {
    func identify(imageData: Data, organ: String) async throws -> [PlantNetCandidate]
}

extension PlantNetClient: PlantIdentifying {}
