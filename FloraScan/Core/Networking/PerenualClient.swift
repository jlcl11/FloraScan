//
//  PerenualClient.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation
import os

actor PerenualClient {
    enum ClientError: Error, LocalizedError {
        case noAPIKey
        case badResponse(Int)
        case rateLimited
        case decoding(Error)
        case noResults

        var errorDescription: String? {
            switch self {
            case .noAPIKey: "Perenual API key not configured."
            case .badResponse(let code): "Perenual returned \(code)."
            case .rateLimited: "Perenual query limit reached."
            case .decoding(let e): "Decoding error: \(e.localizedDescription)"
            case .noResults: "No results."
            }
        }
    }

    private let apiKey: String
    private let session: URLSession
    private let baseURL = URL(string: "https://perenual.com/api/v2")!

    init(apiKey: String, session: URLSession? = nil) {
        self.apiKey = apiKey
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15
            self.session = URLSession(configuration: config)
        }
    }

    /// Convenience init from Secrets.plist.
    init?() {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url),
              let key = dict["PerenualAPIKey"] as? String,
              !key.isEmpty else {
            return nil
        }
        self.apiKey = key
        self.session = .shared
    }

    /// Search species by scientific name.
    func searchSpecies(query: String) async throws -> [PerenualSpecies] {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("species-list"),
                                              resolvingAgainstBaseURL: false) else {
            throw ClientError.badResponse(0)
        }
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: query)
        ]

        guard let requestURL = components.url else { throw ClientError.badResponse(0) }
        let (data, response) = try await fetchData(from: requestURL)
        try validateResponse(response)

        do {
            let decoded = try JSONDecoder().decode(PerenualSearchResponse.self, from: data)
            return decoded.data
        } catch {
            throw ClientError.decoding(error)
        }
    }

    /// Get detailed care profile for a species.
    func careDetails(speciesID: Int) async throws -> PerenualCareProfile {
        let url = baseURL.appendingPathComponent("species/details/\(speciesID)")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw ClientError.badResponse(0)
        }
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        guard let requestURL = components.url else { throw ClientError.badResponse(0) }
        let (data, response) = try await fetchData(from: requestURL)
        try validateResponse(response)

        do {
            let detail = try JSONDecoder().decode(PerenualDetailResponse.self, from: data)
            return PerenualCareProfile.from(detail: detail)
        } catch {
            throw ClientError.decoding(error)
        }
    }

    // MARK: - Private

    private func fetchData(from url: URL) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(from: url)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet
            || urlError.code == .networkConnectionLost {
            throw urlError
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.badResponse(0)
        }
        if http.statusCode == 429 { throw ClientError.rateLimited }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.badResponse(http.statusCode)
        }
    }
}
