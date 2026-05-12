//
//  View+CompatibleGlass.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

extension View {
    /// Liquid Glass with custom shape and optional tint.
    /// Falls back to solid material when Reduce Transparency is active.
    @ViewBuilder
    func glassed<S: Shape>(
        in shape: S,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        GlassedModifier(shape: shape, tint: tint, interactive: interactive) {
            self
        }
    }

    /// Convenience: glassed with Capsule (most common).
    func glassed(tint: Color? = nil, interactive: Bool = false) -> some View {
        glassed(in: Capsule(), tint: tint, interactive: interactive)
    }

    /// Card with glass effect and 18pt corner radius.
    func glassedCard() -> some View {
        glassed(in: RoundedRectangle(cornerRadius: Radius.cardMedium))
    }
}

private struct GlassedModifier<S: Shape, Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let shape: S
    let tint: Color?
    let interactive: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        if reduceTransparency {
            // Solid fallback for Reduce Transparency
            content()
                .background(Palette.Dynamic.surfaceElev, in: shape)
                .overlay(shape.stroke(Palette.borderSubtle, lineWidth: 0.5))
        } else if let tint, interactive {
            content()
                .glassEffect(.regular.tint(tint).interactive(), in: shape)
        } else if let tint {
            content()
                .glassEffect(.regular.tint(tint), in: shape)
        } else if interactive {
            content()
                .glassEffect(.regular.interactive(), in: shape)
        } else {
            content()
                .glassEffect(.regular, in: shape)
        }
    }
}
