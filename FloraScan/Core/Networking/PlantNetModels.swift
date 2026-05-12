//
//  PlantNetModels.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation

// MARK: - API Response
// These must be nonisolated so they can be decoded inside the PlantNetClient actor.

nonisolated struct PlantNetResponse: Sendable {
    let results: [PlantNetResult]
    let remainingIdentificationRequests: Int?
}

nonisolated extension PlantNetResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case results
        case remainingIdentificationRequests
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.results = (try? container.decode([PlantNetResult].self, forKey: .results)) ?? []
        self.remainingIdentificationRequests = try? container.decode(Int.self, forKey: .remainingIdentificationRequests)
    }
}

nonisolated struct PlantNetResult: Sendable {
    let score: Double
    let species: PlantNetSpecies
    let gbif: PlantNetGBIF?
}

nonisolated extension PlantNetResult: Decodable {
    enum CodingKeys: String, CodingKey {
        case score, species, gbif
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.score = (try? container.decode(Double.self, forKey: .score)) ?? 0
        self.species = try container.decode(PlantNetSpecies.self, forKey: .species)
        self.gbif = try? container.decode(PlantNetGBIF.self, forKey: .gbif)
    }
}

nonisolated struct PlantNetSpecies: Decodable, Sendable {
    let scientificNameWithoutAuthor: String
    let scientificName: String?
    let genus: PlantNetTaxon?
    let family: PlantNetTaxon?
    let commonNames: [String]?
}

nonisolated struct PlantNetTaxon: Decodable, Sendable {
    let scientificNameWithoutAuthor: String?
    let scientificName: String?
}

nonisolated struct PlantNetGBIF: Decodable, Sendable {
    let id: Int?
}

// MARK: - App-facing candidate

nonisolated struct PlantNetCandidate: Equatable, Identifiable, Sendable {
    let id = UUID()
    let scientificName: String
    let commonNames: [String]
    let score: Double
    let gbifID: Int?
    let familyName: String?

    var preferredCommonName: String {
        commonNames.first ?? scientificName
    }

    init(from result: PlantNetResult) {
        self.scientificName = result.species.scientificNameWithoutAuthor
        self.commonNames = result.species.commonNames ?? []
        self.score = result.score
        self.gbifID = result.gbif?.id
        self.familyName = result.species.family?.scientificNameWithoutAuthor
    }

    init(scientificName: String, commonNames: [String], score: Double, gbifID: Int? = nil, familyName: String? = nil) {
        self.scientificName = scientificName
        self.commonNames = commonNames
        self.score = score
        self.gbifID = gbifID
        self.familyName = familyName
    }
}
