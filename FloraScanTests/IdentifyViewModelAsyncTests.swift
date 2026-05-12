//
//  IdentifyViewModelAsyncTests.swift
//  FloraScanTests
//
//  Created by José Luis Corral López on 29/4/26.
//

import Testing
import Foundation
import CoreImage
@testable import FloraScan

@Suite("IdentifyViewModel Async Identification")
@MainActor
struct IdentifyViewModelAsyncTests {

    private func makeCIImage() -> CIImage {
        CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 224, height: 224))
    }

    // MARK: - API Success Path

    @Test("API result with high confidence becomes state.results")
    func apiHighConfidence() async {
        let mockAPI = MockPlantIdentifier()
        mockAPI.result = [
            PlantNetCandidate(
                scientificName: "Olea europaea",
                commonNames: ["Olivo"],
                score: 0.92,
                gbifID: 3172363,
                familyName: "Oleaceae"
            )
        ]
        let mockML = MockPlantClassifier()
        mockML.result = [] // No local results

        let vm = IdentifyViewModel(plantNet: mockAPI, classifier: mockML)
        await vm.identify(imageData: Data([0xFF]), ciImage: makeCIImage())

        #expect(vm.state.resultValue?.scientificName == "Olea europaea")
        #expect(vm.state.resultValue?.confidence == 0.92)
        #expect(vm.state.resultValue?.source == .api)
        #expect(mockAPI.callCount == 1)
    }

    // MARK: - Local Fallback

    @Test("Local result shown when API fails")
    func localFallbackOnAPIFailure() async {
        let mockAPI = MockPlantIdentifier()
        mockAPI.error = PlantNetClient.ClientError.noConnection

        let mockML = MockPlantClassifier()
        mockML.result = [
            LocalCandidate(label: "rosa", confidence: 0.85)
        ]

        let vm = IdentifyViewModel(plantNet: mockAPI, classifier: mockML)
        await vm.identify(imageData: Data([0xFF]), ciImage: makeCIImage())

        #expect(vm.state.resultValue != nil)
        #expect(vm.state.resultValue?.source == .local)
        #expect(vm.state.resultValue?.scientificName == "Rosa")
    }

    // MARK: - No API Configured

    @Test("Works with nil API client (local only)")
    func noAPIClient() async {
        let mockML = MockPlantClassifier()
        mockML.result = [
            LocalCandidate(label: "olea_europaea", confidence: 0.75)
        ]

        let vm = IdentifyViewModel(plantNet: nil, classifier: mockML)
        await vm.identify(imageData: Data([0xFF]), ciImage: makeCIImage())

        #expect(vm.state.resultValue != nil)
        #expect(vm.state.resultValue?.source == .local)
    }

    // MARK: - Upgrade Never Downgrade

    @Test("API does not downgrade a better local result")
    func upgradeNeverDowngrade() async {
        let mockAPI = MockPlantIdentifier()
        mockAPI.result = [
            PlantNetCandidate(
                scientificName: "Rosa gallica",
                commonNames: ["Rosa"],
                score: 0.25 // Low confidence
            )
        ]

        let mockML = MockPlantClassifier()
        mockML.result = [
            LocalCandidate(label: "rosa", confidence: 0.80) // High confidence
        ]

        let vm = IdentifyViewModel(plantNet: mockAPI, classifier: mockML)
        await vm.identify(imageData: Data([0xFF]), ciImage: makeCIImage())

        // Local had 0.80 confidence, API only 0.25 — should keep local
        #expect(vm.state.resultValue?.source == .local)
        #expect(vm.state.resultValue?.confidence == 0.80)
    }

    @Test("API upgrades a worse local result")
    func apiUpgradesLocal() async {
        let mockAPI = MockPlantIdentifier()
        mockAPI.result = [
            PlantNetCandidate(
                scientificName: "Olea europaea",
                commonNames: ["Olivo"],
                score: 0.95
            )
        ]

        let mockML = MockPlantClassifier()
        mockML.result = [
            LocalCandidate(label: "olea_europaea", confidence: 0.40)
        ]

        let vm = IdentifyViewModel(plantNet: mockAPI, classifier: mockML)
        await vm.identify(imageData: Data([0xFF]), ciImage: makeCIImage())

        #expect(vm.state.resultValue?.source == .api)
        #expect(vm.state.resultValue?.confidence == 0.95)
    }

    // MARK: - Both Fail

    @Test("Failed state when both API and local return nothing useful")
    func bothFail() async {
        let mockAPI = MockPlantIdentifier()
        mockAPI.error = PlantNetClient.ClientError.noConnection

        let mockML = MockPlantClassifier()
        mockML.result = [] // No results

        let vm = IdentifyViewModel(plantNet: mockAPI, classifier: mockML)
        await vm.identify(imageData: Data([0xFF]), ciImage: makeCIImage())

        #expect(vm.state.errorMessage != nil)
    }

    // MARK: - Re-entry Guard

    @Test("Second identify call is ignored while identifying")
    func reentryGuard() async {
        let mockAPI = MockPlantIdentifier()
        mockAPI.result = [
            PlantNetCandidate(scientificName: "Rosa", commonNames: ["Rosa"], score: 0.9)
        ]
        let mockML = MockPlantClassifier()

        let vm = IdentifyViewModel(plantNet: mockAPI, classifier: mockML)

        // First call
        async let first: () = vm.identify(imageData: Data([0x01]), ciImage: makeCIImage())
        // Second call while first is in progress — should be rejected
        async let second: () = vm.identify(imageData: Data([0x02]), ciImage: makeCIImage())

        await first
        await second

        // API should only be called once (second call rejected by guard)
        #expect(mockAPI.callCount == 1)
    }

    // MARK: - State Cleanup

    @Test("showResultSheet is true during identification")
    func sheetShownDuringIdentify() async {
        let mockAPI = MockPlantIdentifier()
        mockAPI.result = []
        let mockML = MockPlantClassifier()
        mockML.result = []

        let vm = IdentifyViewModel(plantNet: mockAPI, classifier: mockML)
        await vm.identify(imageData: Data([0xFF]), ciImage: makeCIImage())

        #expect(vm.showResultSheet == true)
    }
}
