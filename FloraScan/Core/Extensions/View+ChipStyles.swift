//
//  View+ChipStyles.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

extension View {
    /// Neutral chip with tinted background.
    func fsChip() -> some View {
        self
            .font(.fsCaption2)
            .foregroundStyle(Palette.Dynamic.textPrimary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Palette.Dynamic.surfaceTinted, in: Capsule())
    }

    /// Glass chip for overlays on photos/camera.
    func fsChipGlass() -> some View {
        self
            .font(.fsCaption2)
            .foregroundStyle(Palette.Dynamic.textPrimary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .glassed(in: Capsule())
    }

    /// Leaf chip — solid green for tags like "Healthy", "Mediterranean".
    func fsChipLeaf() -> some View {
        self
            .font(.fsCaption2)
            .foregroundStyle(Palette.textOnLeaf)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Palette.leaf700, in: Capsule())
    }
}
