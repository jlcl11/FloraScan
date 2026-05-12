//
//  ModelLoader.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import CoreML
import Vision

nonisolated enum ModelLoader {
    static func loadVisionModel() throws -> VNCoreMLModel {
        // Try compiled model first, then mlpackage, then known model names
        guard let url = Bundle.main.url(forResource: "PlantClassifier", withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: "PlantClassifier", withExtension: "mlpackage")
            ?? Bundle.main.url(forResource: "FlowerClassifier", withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: "FlowerClassifier", withExtension: "mlmodel")
            ?? Bundle.main.url(forResource: "Oxford102Flowers", withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: "Oxford102Flowers", withExtension: "mlmodel") else {
            throw NSError(
                domain: "ModelLoader",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No ML model found in bundle."]
            )
        }
        let config = MLModelConfiguration()
        config.computeUnits = .all  // CPU + GPU + Neural Engine
        let model = try MLModel(contentsOf: url, configuration: config)
        return try VNCoreMLModel(for: model)
    }
}
