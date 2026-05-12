//
//  PlantClassifier.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Vision
import CoreML
import CoreImage

actor PlantClassifier {
    enum ClassifierError: Error {
        case modelNotLoaded, noResults
    }

    private var visionModel: VNCoreMLModel?

    func loadIfNeeded() throws {
        guard visionModel == nil else { return }
        visionModel = try ModelLoader.loadVisionModel()
    }

    func classify(
        ciImage: CIImage,
        orientation: CGImagePropertyOrientation = .up
    ) async throws -> [LocalCandidate] {
        try loadIfNeeded()
        guard let model = visionModel else { throw ClassifierError.modelNotLoaded }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { req, err in
                if let err {
                    continuation.resume(throwing: err)
                    return
                }
                guard let observations = req.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: ClassifierError.noResults)
                    return
                }
                let top5 = observations.prefix(5).map {
                    LocalCandidate(label: $0.identifier, confidence: Double($0.confidence))
                }
                continuation.resume(returning: top5)
            }
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(
                ciImage: ciImage,
                orientation: orientation,
                options: [:]
            )
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
