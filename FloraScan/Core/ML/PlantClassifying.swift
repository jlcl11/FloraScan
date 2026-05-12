//
//  PlantClassifying.swift
//  FloraScan
//
//  Created by José Luis Corral López on 29/4/26.
//

import CoreImage

/// Abstraction for local ML classification (Core ML or mock).
protocol PlantClassifying: Sendable {
    func classify(ciImage: CIImage, orientation: CGImagePropertyOrientation) async throws -> [LocalCandidate]
}

extension PlantClassifier: PlantClassifying {}
