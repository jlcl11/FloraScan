//
//  Logger+App.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import os

nonisolated extension Logger {
    static let persistence = Logger(subsystem: "io.jlcl11.florascan", category: "persistence")
    static let camera = Logger(subsystem: "io.jlcl11.florascan", category: "camera")
    static let ml = Logger(subsystem: "io.jlcl11.florascan", category: "ml")
    static let network = Logger(subsystem: "io.jlcl11.florascan", category: "network")
    static let notifications = Logger(subsystem: "io.jlcl11.florascan", category: "notifications")
}
