//
//  PulsingShutterButton.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct PulsingShutterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 4)
                Circle()
                    .fill(.white)
                    .padding(8)
            }
            .frame(width: 78, height: 78)
        }
        .buttonStyle(.plain)
        .phaseAnimator([1.0, 1.06, 1.0]) { content, scale in
            content.scaleEffect(scale)
        } animation: { _ in
            .smooth(duration: 1.4)
        }
        .accessibilityLabel("Capturar foto")
        .accessibilityHint("Captura una foto de la planta para identificarla")
    }
}
