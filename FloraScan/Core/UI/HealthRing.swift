//
//  HealthRing.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct HealthRing: View {
    let value: Double          // 0.0...1.0, clamped internally
    var size: CGFloat = 32
    var stroke: CGFloat = 3
    var label: String?

    private var safeValue: Double {
        value.isFinite ? max(0, min(1, value)) : 0
    }

    private var color: Color {
        switch safeValue {
        case 0.7...: Palette.healthOk
        case 0.4..<0.7: Palette.healthWarning
        default: Palette.healthCritical
        }
    }

    private var statusLabel: String {
        switch safeValue {
        case 0.7...: "optimal"
        case 0.4..<0.7: "moderate"
        default: "critical"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)

            Circle()
                .stroke(Palette.borderDefault, lineWidth: stroke)
                .padding(stroke)

            Circle()
                .trim(from: 0, to: safeValue)
                .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .padding(stroke)
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.6), value: safeValue)

            if let label {
                Text(label)
                    .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Health \(Int(safeValue * 100)) percent, \(statusLabel)")
    }
}

#Preview {
    HStack(spacing: 20) {
        HealthRing(value: 0.92, size: 28, stroke: 2.5)
        HealthRing(value: 0.92, size: 48, stroke: 3, label: "92")
        HealthRing(value: 0.55, size: 56, stroke: 3.5, label: "55")
        HealthRing(value: 0.25, size: 56, stroke: 3.5, label: "25")
    }
    .padding()
}
