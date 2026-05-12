//
//  WikipediaClient.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation
import os

actor WikipediaClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetch the summary extract from the Spanish Wikipedia for a given scientific name.
    /// Falls back to English Wikipedia if no Spanish article exists.
    func summary(scientificName: String) async -> String? {
        // Try Spanish first
        if let result = await fetchSummary(scientificName: scientificName, lang: "es") {
            return result
        }
        // Fallback to English
        return await fetchSummary(scientificName: scientificName, lang: "en")
    }

    private func fetchSummary(scientificName: String, lang: String) async -> String? {
        let title = scientificName
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? scientificName

        guard let url = URL(string: "https://\(lang).wikipedia.org/api/rest_v1/page/summary/\(title)") else {
            return nil
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                return nil
            }
            let decoded = try JSONDecoder().decode(WikiSummary.self, from: data)
            return decoded.extract
        } catch {
            Logger.network.debug("Wikipedia fetch failed for \(scientificName) (\(lang)): \(error.localizedDescription)")
            return nil
        }
    }
}

private nonisolated struct WikiSummary: Decodable {
    let extract: String?
}
