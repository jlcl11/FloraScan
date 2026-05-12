//
//  Wordmark.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct Wordmark: View {
    var color: Color = .white
    var opacity: Double = 0.7

    var body: some View {
        Text("FLORASCAN")
            .font(.fsMonoCap)
            .tracking(2)
            .foregroundStyle(color.opacity(opacity))
            .accessibilityLabel("FloraScan")
    }
}

#Preview {
    ZStack {
        Color.black
        Wordmark()
    }
}
