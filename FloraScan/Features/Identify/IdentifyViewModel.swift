//
//  IdentifyViewModel.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import CoreImage
import os

@MainActor
@Observable
final class IdentifyViewModel {
    enum State: Equatable {
        case idle
        case identifying
        case results(ClassificationResult)
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var liveResult: ClassificationResult?
    var capturedPhoto: Data?
    var showResultSheet = false

    private let plantNet: (any PlantIdentifying)?
    private let classifier: any PlantClassifying

    init(plantNet: (any PlantIdentifying)? = nil, classifier: any PlantClassifying = PlantClassifier()) {
        self.plantNet = plantNet
        self.classifier = classifier
    }

    /// Classify a single frame for live preview (lightweight — local only)
    func classifyFrame(ciImage: CIImage, orientation: CGImagePropertyOrientation) async -> ClassificationResult? {
        do {
            let locals = try await classifier.classify(ciImage: ciImage, orientation: orientation)
            guard let top = locals.first, top.confidence > 0.3 else { return nil }
            let result = ClassificationResult.fromLocal(label: top.label, confidence: top.confidence)
            liveResult = result
            return result
        } catch {
            return nil
        }
    }

    /// Full identification: API + local in parallel.
    /// Shows local result immediately, then upgrades to API result if better.
    func identify(imageData: Data, ciImage: CIImage, organ: String = "auto") async {
        guard state != .identifying else { return }

        state = .identifying
        capturedPhoto = imageData
        showResultSheet = true
        lastAPIError = nil

        // Run both in parallel but show local result as soon as it arrives
        async let apiTask = identifyAPI(imageData: imageData, organ: organ)
        let localResult = await identifyLocal(ciImage: ciImage)

        // Show local result immediately if available
        var shownConfidence: Double = 0
        if let top = localResult.first, top.confidence > 0.3 {
            let localBest = ClassificationResult.fromLocal(label: top.label, confidence: top.confidence)
            state = .results(localBest)
            shownConfidence = localBest.confidence
        }

        guard !Task.isCancelled else { return }

        // Wait for API — only upgrade, never downgrade
        let apiResult = await apiTask

        guard !Task.isCancelled else { return }

        let best = chooseBestGuess(api: apiResult, local: localResult)

        if let best, best.confidence > shownConfidence {
            state = .results(best)
        } else if state.resultValue == nil {
            let detail = lastAPIError ?? "Try with another photo or get closer."
            state = .failed("Could not identify the plant. \(detail)")
        }
    }

    func reset() {
        state = .idle
        capturedPhoto = nil
        showResultSheet = false
        lastAPIError = nil
        liveResult = nil
    }

    func fail(message: String) {
        state = .failed(message)
        showResultSheet = true
    }

    // MARK: - Private

    private var lastAPIError: String?

    private func identifyAPI(imageData: Data, organ: String) async -> ClassificationResult? {
        guard let plantNet else {
            lastAPIError = "API not configured. Add your Pl@ntNet key to Secrets.plist."
            return nil
        }
        do {
            let candidates = try await plantNet.identify(imageData: imageData, organ: organ)
            lastAPIError = nil
            return ClassificationResult.fromAPI(candidates: candidates)
        } catch let error as LocalizedError {
            lastAPIError = error.errorDescription
            return nil
        } catch {
            lastAPIError = "Network error: \(error.localizedDescription)"
            return nil
        }
    }

    private func identifyLocal(ciImage: CIImage) async -> [LocalCandidate] {
        do {
            return try await classifier.classify(ciImage: ciImage, orientation: .up)
        } catch {
            Logger.ml.error("Local classification failed: \(error.localizedDescription)")
            return []
        }
    }

    private func chooseBestGuess(api: ClassificationResult?, local: [LocalCandidate]) -> ClassificationResult? {
        // Rule 1: API with score > 0.4 wins (broader coverage)
        if let api, api.confidence > 0.4 {
            return api
        }
        // Rule 2: Local with confidence > 0.7 as fallback
        if let top = local.first, top.confidence > 0.7 {
            return ClassificationResult.fromLocal(label: top.label, confidence: top.confidence)
        }
        // Rule 3: API with reasonable result (> 0.2 minimum)
        if let api, api.confidence > 0.2 {
            return api
        }
        // Rule 4: Local with any result
        if let top = local.first, top.confidence > 0.3 {
            return ClassificationResult.fromLocal(label: top.label, confidence: top.confidence)
        }
        return nil
    }
}

extension IdentifyViewModel.State {
    var resultValue: ClassificationResult? {
        if case .results(let r) = self { return r }
        return nil
    }

    var isIdentifying: Bool {
        if case .identifying = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .failed(let msg) = self { return msg }
        return nil
    }
}
