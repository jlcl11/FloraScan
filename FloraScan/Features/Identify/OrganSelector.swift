//
//  OrganSelector.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct OrganSelector: View {
    @Binding var selected: PlantOrgan
    @Namespace private var glassNS

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(PlantOrgan.allCases, id: \.self) { organ in
                    Button {
                        withAnimation(.smooth(duration: 0.3)) {
                            selected = organ
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: organ.symbolName)
                                .font(.fsCallout)
                            Text(organ.displayName)
                                .font(.fsCaption2)
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .frame(minWidth: 56)
                    }
                    .buttonStyle(.plain)
                    .glassed(
                        in: .rect(cornerRadius: 12),
                        tint: selected == organ ? Palette.primary.opacity(0.6) : nil,
                        interactive: true
                    )
                    .glassEffectID(organ.rawValue, in: glassNS)
                    .accessibilityLabel("\(organ.displayName)\(selected == organ ? ", selected" : "")")
                    .accessibilityHint("Plant organ selector")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Organ selector")
    }
}
