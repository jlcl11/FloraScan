//
//  ModelContext+SafeSave.swift
//  FloraScan
//
//  Created by José Luis Corral López on 29/4/26.
//

import Foundation
import SwiftData
import os

extension ModelContext {
    /// Save with logging. Returns true on success.
    @discardableResult
    func safeSave() -> Bool {
        do {
            try save()
            return true
        } catch {
            Logger.persistence.error("ModelContext.save() failed: \(error.localizedDescription)")
            return false
        }
    }
}
