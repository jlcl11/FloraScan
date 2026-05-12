//
//  ConfidenceBar.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct ConfidenceBar: View {
    let value: Double

    private var color: Color {
        switch value {
        case 0.7...: Palette.healthOk
        case 0.4..<0.7: Palette.healthWarning
        default: Palette.healthCritical
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.gray.opacity(0.2))
                Capsule()
                    .fill(color.gradient)
                    .frame(width: max(4, geo.size.width * min(1.0, max(0.0, value))))
                    .animation(.smooth(duration: 0.5), value: value)
            }
        }
    }
}
