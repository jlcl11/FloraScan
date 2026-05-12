//
//  MockPlantIdentifier.swift
//  FloraScanTests
//
//  Created by José Luis Corral López on 29/4/26.
//

import Foundation
@testable import FloraScan

/// Mock PlantIdentifying for tests. Returns preconfigured results or throws.
final class MockPlantIdentifier: PlantIdentifying, @unchecked Sendable {
    var result: [PlantNetCandidate] = []
    var error: Error?
    var callCount = 0

    func identify(imageData: Data, organ: String) async throws -> [PlantNetCandidate] {
        callCount += 1
        if let error { throw error }
        return result
    }
}
