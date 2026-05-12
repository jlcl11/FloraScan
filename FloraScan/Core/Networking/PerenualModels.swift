//
//  PerenualModels.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation

nonisolated struct PerenualSearchResponse: Decodable, Sendable {
    let data: [PerenualSpecies]
}

nonisolated struct PerenualSpecies: Decodable, Sendable, Identifiable {
    let id: Int
    let commonName: String?
    let scientificName: [String]?
    let cycle: String?
    let watering: String?
    let sunlight: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case commonName = "common_name"
        case scientificName = "scientific_name"
        case cycle
        case watering
        case sunlight
    }

    var primaryScientificName: String? {
        scientificName?.first
    }
}

nonisolated struct PerenualDetailResponse: Decodable, Sendable {
    let id: Int
    let commonName: String?
    let watering: String?
    let sunlight: [String]?
    let pruningMonth: [String]?
    let cycle: String?
    let careLevel: String?
    let flowers: Bool?
    let fruits: Bool?
    let edibleFruit: Bool?
    let poisonousToHumans: Int?
    let poisonousToPets: Int?
    let indoor: Bool?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case commonName = "common_name"
        case watering
        case sunlight
        case pruningMonth = "pruning_month"
        case cycle
        case careLevel = "care_level"
        case flowers
        case fruits
        case edibleFruit = "edible_fruit"
        case poisonousToHumans = "poisonous_to_humans"
        case poisonousToPets = "poisonous_to_pets"
        case indoor
        case description
    }
}

nonisolated struct PerenualCareProfile: Sendable {
    let wateringFrequency: WateringFrequency
    let pruningMonths: [Int]
    let sunlight: [String]
    let cycle: String?
    let careLevel: String?
    let isPoisonousToHumans: Bool
    let isPoisonousToPets: Bool
    let isIndoor: Bool
    let description: String?

    enum WateringFrequency: Sendable {
        case frequent    // every 2-3 days
        case average     // every 5-7 days
        case minimum     // every 10-14 days
        case none        // unknown

        var intervalDays: Int {
            switch self {
            case .frequent: 3
            case .average: 7
            case .minimum: 12
            case .none: 7
            }
        }
    }

    static func from(detail: PerenualDetailResponse) -> PerenualCareProfile {
        let watering: WateringFrequency = switch detail.watering?.lowercased() {
        case "frequent": .frequent
        case "average": .average
        case "minimum", "none": .minimum
        default: .none
        }

        let months = (detail.pruningMonth ?? []).compactMap { monthNameToNumber($0) }

        return PerenualCareProfile(
            wateringFrequency: watering,
            pruningMonths: months,
            sunlight: detail.sunlight ?? [],
            cycle: detail.cycle,
            careLevel: detail.careLevel,
            isPoisonousToHumans: (detail.poisonousToHumans ?? 0) > 0,
            isPoisonousToPets: (detail.poisonousToPets ?? 0) > 0,
            isIndoor: detail.indoor ?? false,
            description: detail.description
        )
    }

    private static func monthNameToNumber(_ name: String) -> Int? {
        let map = [
            "january": 1, "february": 2, "march": 3, "april": 4,
            "may": 5, "june": 6, "july": 7, "august": 8,
            "september": 9, "october": 10, "november": 11, "december": 12
        ]
        return map[name.lowercased()]
    }
}
