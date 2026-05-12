//
//  ClassificationResultTests.swift
//  FloraScanTests
//
//  Created by José Luis Corral López on 29/4/26.
//

import Testing
import Foundation
@testable import FloraScan

@Suite("ClassificationResult")
struct ClassificationResultTests {

    // MARK: - From Local

    @Test("fromLocal formats underscored label as scientific name")
    func localFormatsName() {
        let result = ClassificationResult.fromLocal(label: "olea_europaea", confidence: 0.85)

        #expect(result.scientificName == "Olea europaea")
        #expect(result.commonName == "Olea Europaea")
        #expect(result.confidence == 0.85)
        #expect(result.source == .local)
        #expect(result.alternatives.isEmpty)
        #expect(result.familyName == nil)
        #expect(result.gbifID == nil)
    }

    @Test("fromLocal handles single-word label")
    func localSingleWord() {
        let result = ClassificationResult.fromLocal(label: "rosa", confidence: 0.6)
        #expect(result.scientificName == "Rosa")
        #expect(result.commonName == "Rosa")
    }

    // MARK: - From API

    @Test("fromAPI extracts top candidate and alternatives")
    func apiParsing() {
        let candidates = [
            PlantNetCandidate(scientificName: "Olea europaea", commonNames: ["Olivo"], score: 0.92, gbifID: 3172363, familyName: "Oleaceae"),
            PlantNetCandidate(scientificName: "Olea cuspidata", commonNames: ["Olivo africano"], score: 0.05, familyName: nil),
        ]

        let result = ClassificationResult.fromAPI(candidates: candidates)

        #expect(result != nil)
        #expect(result?.scientificName == "Olea europaea")
        #expect(result?.commonName == "Olivo")
        #expect(result?.confidence == 0.92)
        #expect(result?.familyName == "Oleaceae")
        #expect(result?.gbifID == 3172363)
        #expect(result?.source == .api)
        #expect(result?.alternatives.count == 1)
        #expect(result?.alternatives.first?.scientificName == "Olea cuspidata")
    }

    @Test("fromAPI returns nil for empty candidates")
    func apiEmpty() {
        let result = ClassificationResult.fromAPI(candidates: [])
        #expect(result == nil)
    }

    // MARK: - Equatable

    @Test("Two results with same data are equal")
    func equality() {
        let a = ClassificationResult.fromLocal(label: "rosa", confidence: 0.8)
        let b = ClassificationResult.fromLocal(label: "rosa", confidence: 0.8)
        #expect(a == b)
    }

    @Test("Different confidence makes results unequal")
    func inequalityConfidence() {
        let a = ClassificationResult.fromLocal(label: "rosa", confidence: 0.8)
        let b = ClassificationResult.fromLocal(label: "rosa", confidence: 0.5)
        #expect(a != b)
    }
}
