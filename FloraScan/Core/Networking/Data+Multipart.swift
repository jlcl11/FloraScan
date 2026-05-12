//
//  Data+Multipart.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation

extension Data {
    nonisolated mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
