//
//  IdentifyViewModelTests.swift
//  FloraScanTests
//
//  Created by José Luis Corral López on 29/4/26.
//

import Testing
import Foundation
@testable import FloraScan

@Suite("IdentifyViewModel State Machine")
@MainActor
struct IdentifyViewModelTests {

    @Test("Initial state is idle")
    func initialState() {
        let vm = IdentifyViewModel(plantNet: nil)
        #expect(vm.state == .idle)
        #expect(vm.capturedPhoto == nil)
        #expect(vm.showResultSheet == false)
        #expect(vm.liveResult == nil)
    }

    @Test("reset clears all state")
    func resetClearsState() {
        let vm = IdentifyViewModel(plantNet: nil)
        vm.capturedPhoto = Data([0x00])
        vm.showResultSheet = true
        vm.reset()

        #expect(vm.state == .idle)
        #expect(vm.capturedPhoto == nil)
        #expect(vm.showResultSheet == false)
        #expect(vm.liveResult == nil)
    }

    @Test("fail sets failed state and shows sheet")
    func failSetsState() {
        let vm = IdentifyViewModel(plantNet: nil)
        vm.fail(message: "Error de prueba")

        #expect(vm.state == .failed("Error de prueba"))
        #expect(vm.showResultSheet == true)
    }

    @Test("State.resultValue extracts result from .results case")
    func resultValueExtraction() {
        let result = ClassificationResult.fromLocal(label: "rosa", confidence: 0.85)
        let state = IdentifyViewModel.State.results(result)
        #expect(state.resultValue == result)
    }

    @Test("State.resultValue returns nil for non-results cases")
    func resultValueNilForOther() {
        #expect(IdentifyViewModel.State.idle.resultValue == nil)
        #expect(IdentifyViewModel.State.identifying.resultValue == nil)
        #expect(IdentifyViewModel.State.failed("err").resultValue == nil)
    }

    @Test("State.isIdentifying only for identifying case")
    func isIdentifyingFlag() {
        #expect(IdentifyViewModel.State.identifying.isIdentifying == true)
        #expect(IdentifyViewModel.State.idle.isIdentifying == false)
    }

    @Test("State.errorMessage extracts from failed case")
    func errorMessageExtraction() {
        #expect(IdentifyViewModel.State.failed("msg").errorMessage == "msg")
        #expect(IdentifyViewModel.State.idle.errorMessage == nil)
    }
}
