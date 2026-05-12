//
//  AppContainer.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import Foundation

@MainActor
enum AppContainer {
    /// PlantNet client initialized from Secrets.plist, nil if no API key
    static let plantNetClient: (any PlantIdentifying)? = PlantNetClient()

    /// Perenual client initialized from Secrets.plist, nil if no API key
    static let perenualClient: PerenualClient? = PerenualClient()
}
