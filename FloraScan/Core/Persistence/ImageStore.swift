//
//  ImageStore.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import UIKit
import SwiftData
import os

nonisolated enum ImageStore {
    private static var plantsDirectory: URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return URL.temporaryDirectory.appendingPathComponent("Plants", isDirectory: true)
        }
        let dir = docs.appendingPathComponent("Plants", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static let maxFileSize = 5_000_000 // 5 MB

    // NSCache is thread-safe internally but doesn't conform to Sendable
    nonisolated(unsafe) private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 80
        c.totalCostLimit = 50_000_000 // ~50 MB
        return c
    }()

    @discardableResult
    static func save(data: Data, fileName: String) -> Bool {
        guard data.count <= maxFileSize else {
            Logger.persistence.warning("Image too large (\(data.count) bytes), rejected: \(fileName)")
            return false
        }
        guard !fileName.contains("/"), !fileName.contains("..") else {
            Logger.persistence.error("Invalid fileName rejected: \(fileName)")
            return false
        }
        let url = plantsDirectory.appendingPathComponent(fileName)
        do {
            if let image = UIImage(data: data),
               let jpeg = image.jpegData(compressionQuality: 0.85) {
                try jpeg.write(to: url)
                cache.setObject(image, forKey: fileName as NSString)
            } else {
                try data.write(to: url)
            }
            return true
        } catch {
            Logger.persistence.error("Failed to save image \(fileName): \(error.localizedDescription)")
            return false
        }
    }

    static func load(fileName: String) -> UIImage? {
        if let cached = cache.object(forKey: fileName as NSString) {
            return cached
        }
        let url = plantsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: fileName as NSString)
        return image
    }

    static func delete(fileName: String) {
        cache.removeObject(forKey: fileName as NSString)
        let url = plantsDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    /// Remove photo files that are not referenced by any PlantPhoto record.
    @MainActor
    static func cleanupOrphans(context: ModelContext) {
        let dir = plantsDirectory
        guard let filesOnDisk = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }

        let descriptor = FetchDescriptor<PlantPhoto>()
        guard let allPhotos: [PlantPhoto] = try? context.fetch(descriptor) else { return }
        let referencedFiles: Set<String> = Set(allPhotos.map { $0.fileName })

        var removed = 0
        for file in filesOnDisk {
            guard !referencedFiles.contains(file) else { continue }
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(file))
            removed += 1
        }
        if removed > 0 {
            Logger.persistence.info("Cleaned up \(removed) orphaned photo files")
        }
    }

    static func deleteAll() {
        cache.removeAllObjects()
        let dir = plantsDirectory
        if let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) {
            for file in files {
                try? FileManager.default.removeItem(at: dir.appendingPathComponent(file))
            }
        }
    }
}
