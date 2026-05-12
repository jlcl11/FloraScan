//
//  FSCard.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct FSCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(Spacing.s4)
            .background(
                Palette.Dynamic.surfaceCard,
                in: .rect(cornerRadius: Radius.cardMedium)
            )
            .fsShadow(1)
    }
}

#Preview {
    FSCard {
        VStack(alignment: .leading, spacing: 4) {
            Text("Olivo")
                .font(.fsHeadline)
            Text("Olea europaea")
                .font(.fsSciDefault)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
