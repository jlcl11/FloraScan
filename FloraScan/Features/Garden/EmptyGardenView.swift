//
//  EmptyGardenView.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct EmptyGardenView: View {
    let onAddPlant: () -> Void

    var body: some View {
        VStack(spacing: Spacing.s5) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Palette.leaf100)
                    .frame(width: 88, height: 88)

                Image(systemName: "square.stack.3d.up.fill")
                    .font(.fsLargeTitle)
                    .foregroundStyle(Palette.leaf700)
            }

            VStack(spacing: Spacing.s2) {
                Text("Your garden is empty")
                    .font(.fsTitle3)
                    .foregroundStyle(Palette.Dynamic.textPrimary)

                Text("Identify your first plant with the camera.")
                    .font(.fsCallout)
                    .foregroundStyle(Palette.Dynamic.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddPlant) {
                Label("Add first plant", systemImage: "plus")
                    .fsButtonProminent()
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, Spacing.s7)
    }
}

#Preview {
    EmptyGardenView { }
}
