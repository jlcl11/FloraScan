//
//  View+ButtonStyles.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

extension View {
    /// Primary button: solid leaf700 background, white text, capsule shape.
    func fsButtonProminent() -> some View {
        self
            .font(.fsHeadline)
            .foregroundStyle(Palette.textOnLeaf)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .background(Palette.leaf700, in: Capsule())
    }

    /// Glass button: Liquid Glass capsule, primary text.
    func fsButtonGlass() -> some View {
        self
            .font(.fsHeadline)
            .foregroundStyle(Palette.Dynamic.textPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .glassed(in: Capsule())
    }

    /// Plain button: green text only, no background.
    func fsButtonPlain() -> some View {
        self
            .font(.fsHeadline)
            .foregroundStyle(Palette.leaf700)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
    }

    /// Destructive button: clay text, no background.
    func fsButtonDestructive() -> some View {
        self
            .font(.fsHeadline)
            .foregroundStyle(Palette.clay700)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
    }
}
