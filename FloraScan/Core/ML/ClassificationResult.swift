//
//  ClassificationResult.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation

nonisolated struct ClassificationResult: Equatable, Sendable {
    let commonName: String
    let scientificName: String
    let confidence: Double
    let familyName: String?
    let gbifID: Int?
    let alternatives: [Alternative]
    let source: Source

    enum Source: String, Equatable, Sendable {
        case api, local, none
    }

    struct Alternative: Equatable, Sendable {
        let commonName: String
        let scientificName: String
        let confidence: Double
    }

    /// Create from PlantNet API candidates
    static func fromAPI(candidates: [PlantNetCandidate]) -> ClassificationResult? {
        guard let top = candidates.first else { return nil }
        return ClassificationResult(
            commonName: top.preferredCommonName,
            scientificName: top.scientificName,
            confidence: top.score,
            familyName: top.familyName,
            gbifID: top.gbifID,
            alternatives: candidates.dropFirst().map {
                Alternative(commonName: $0.preferredCommonName, scientificName: $0.scientificName, confidence: $0.score)
            },
            source: .api
        )
    }

    /// Create from local Core ML candidate
    /// Format scientific name: capitalize only the genus (first word).
    private static func formatScientificName(_ raw: String) -> String {
        let cleaned = raw.replacingOccurrences(of: "_", with: " ")
        let parts = cleaned.split(separator: " ", maxSplits: 1)
        guard let genus = parts.first else { return cleaned }
        let epithet = parts.count > 1 ? " " + parts[1].lowercased() : ""
        return genus.capitalized + epithet
    }

    static func fromLocal(label: String, confidence: Double) -> ClassificationResult {
        let sciName = formatScientificName(label)
        return ClassificationResult(
            commonName: label.replacingOccurrences(of: "_", with: " ").capitalized,
            scientificName: sciName,
            confidence: confidence,
            familyName: nil,
            gbifID: nil,
            alternatives: [],
            source: .local
        )
    }

    static let empty = ClassificationResult(
        commonName: "",
        scientificName: "",
        confidence: 0,
        familyName: nil,
        gbifID: nil,
        alternatives: [],
        source: .none
    )
}
