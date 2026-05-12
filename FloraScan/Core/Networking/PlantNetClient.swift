//
//  PlantNetClient.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation
import os

actor PlantNetClient {
    enum ClientError: Error, LocalizedError {
        case noConnection
        case badResponse(Int)
        case decoding(Error)
        case rateLimited
        case noAPIKey

        var errorDescription: String? {
            switch self {
            case .noConnection: "No internet connection."
            case .badResponse(let code): "Server returned \(code)."
            case .decoding(let e): "Decoding error: \(e.localizedDescription)"
            case .rateLimited: "You have reached the daily identification limit."
            case .noAPIKey: "Pl@ntNet API key not configured."
            }
        }
    }

    private let apiKey: String
    private let session: URLSession
    private let baseURL = URL(string: "https://my-api.plantnet.org/v2/identify/all")!

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Convenience init that reads the API key from Secrets.plist
    init?() {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url),
              let key = dict["PlantNetAPIKey"] as? String,
              !key.isEmpty else {
            return nil
        }
        self.apiKey = key
        self.session = .shared
    }

    func identify(imageData: Data, organ: String = "auto") async throws -> [PlantNetCandidate] {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw ClientError.badResponse(0)
        }
        components.queryItems = [
            URLQueryItem(name: "api-key", value: apiKey),
            URLQueryItem(name: "include-related-images", value: "false")
        ]

        guard let requestURL = components.url else { throw ClientError.badResponse(0) }
        let boundary = UUID().uuidString
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = makeMultipartBody(imageData: imageData, organ: organ, boundary: boundary)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet
            || urlError.code == .networkConnectionLost
            || urlError.code == .dataNotAllowed {
            throw ClientError.noConnection
        }

        guard let http = response as? HTTPURLResponse else {
            throw ClientError.badResponse(0)
        }

        if http.statusCode == 429 { throw ClientError.rateLimited }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.badResponse(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(PlantNetResponse.self, from: data)
            return decoded.results.prefix(5).map { PlantNetCandidate(from: $0) }
        } catch {
            if let raw = String(data: data.prefix(500), encoding: .utf8) {
                Logger.network.error("PlantNet decode failed. Raw: \(raw)")
            }
            throw ClientError.decoding(error)
        }
    }

    private func makeMultipartBody(imageData: Data, organ: String, boundary: String) -> Data {
        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"organs\"\r\n\r\n\(organ)\r\n")
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"images\"; filename=\"photo.jpg\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendString("\r\n--\(boundary)--\r\n")
        return body
    }
}
