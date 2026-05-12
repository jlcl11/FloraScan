//
//  PlantPhoto.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation
import SwiftData

@Model
final class PlantPhoto {
    @Attribute(.unique) var id: UUID = UUID()
    var fileName: String = ""
    var capturedAt: Date = Date()
    var isPrimary: Bool = false
    var plant: Plant?

    init(fileName: String, isPrimary: Bool = false) {
        self.fileName = fileName
        self.isPrimary = isPrimary
    }
}
