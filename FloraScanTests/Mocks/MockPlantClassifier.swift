//
//  MockPlantClassifier.swift
//  FloraScanTests
//
//  Created by José Luis Corral López on 29/4/26.
//

import CoreImage
@testable import FloraScan

/// Mock PlantClassifying for tests. Returns preconfigured local candidates.
final class MockPlantClassifier: PlantClassifying, @unchecked Sendable {
    var result: [LocalCandidate] = []
    var error: Error?
    var callCount = 0

    func classify(ciImage: CIImage, orientation: CGImagePropertyOrientation) async throws -> [LocalCandidate] {
        callCount += 1
        if let error { throw error }
        return result
    }
}
