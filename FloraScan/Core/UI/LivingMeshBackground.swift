//
//  LivingMeshBackground.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct LivingMeshBackground: View {
    let palette: [Color]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            // Static linear gradient fallback
            LinearGradient(
                colors: [palette.first ?? .green, palette.last ?? .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        } else if reduceMotion {
            // Static mesh (no animation)
            staticMesh
                .ignoresSafeArea()
        } else {
            // Animated mesh
            animatedMesh
                .ignoresSafeArea()
        }
    }

    private var staticMesh: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ],
            colors: palette
        )
    }

    private var animatedMesh: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { ctx in
            let t = Float(ctx.date.timeIntervalSinceReferenceDate)
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0],
                    [0.5 + 0.05 * sin(t * 0.4), 0],
                    [1, 0],
                    [0, 0.5 + 0.05 * cos(t * 0.3)],
                    [0.5 + 0.1 * sin(t * 0.2), 0.5 + 0.1 * cos(t * 0.25)],
                    [1, 0.5 + 0.05 * sin(t * 0.35)],
                    [0, 1],
                    [0.5 + 0.05 * cos(t * 0.4), 1],
                    [1, 1]
                ],
                colors: palette
            )
        }
    }
}

// MARK: - Palettes

extension LivingMeshBackground {
    /// Onboarding Hero exclusive palette — diagonal NW green → SE amber.
    static let onboardingHero: [Color] = [
        Color(hex: "#1F5A3F"),
        Color(hex: "#3E8264"),
        Color(hex: "#7AB089"),
        Color(hex: "#5DA271"),
        Color(hex: "#A8C99A"),
        Color(hex: "#D4B88A"),
        Color(hex: "#7B9568"),
        Color(hex: "#B89868"),
        Color(hex: "#E6A85C")
    ]

    /// General nature palette for privacy, camera permission, share, etc.
    static let nature: [Color] = [
        Color(hex: "#0E5C3F").opacity(0.85),
        Color(hex: "#5DA271"),
        Color(hex: "#0E5C3F").opacity(0.85),
        Color(hex: "#5DA271"),
        Color(hex: "#E6A85C"),
        Color(hex: "#5DA271"),
        Color(hex: "#0E5C3F").opacity(0.95),
        Color(hex: "#5DA271"),
        Color(hex: "#0E5C3F").opacity(0.85)
    ]
}

#Preview("Onboarding Hero") {
    LivingMeshBackground(palette: LivingMeshBackground.onboardingHero)
}

#Preview("Nature") {
    LivingMeshBackground(palette: LivingMeshBackground.nature)
}
