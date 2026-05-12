//
//  LightLevelTests.swift
//  FloraScanTests
//
//  Created by José Luis Corral López on 29/4/26.
//

import Testing
@testable import FloraScan

@Suite("LightLevel")
struct LightLevelTests {

    @Test("All cases have display names")
    func allDisplayNames() {
        for level in LightLevel.allCases {
            #expect(!level.displayName.isEmpty)
        }
    }

    @Test("Modifiers are ordered: direct < bright < medium < low")
    func modifierOrder() {
        #expect(LightLevel.direct.modifier < LightLevel.bright.modifier)
        #expect(LightLevel.bright.modifier < LightLevel.medium.modifier)
        #expect(LightLevel.medium.modifier < LightLevel.low.modifier)
    }

    @Test("Raw values round-trip correctly")
    func rawValueRoundTrip() {
        for level in LightLevel.allCases {
            let restored = LightLevel(rawValue: level.rawValue)
            #expect(restored == level)
        }
    }

    @Test("Invalid raw value returns nil")
    func invalidRawValue() {
        #expect(LightLevel(rawValue: "extreme") == nil)
    }
}
