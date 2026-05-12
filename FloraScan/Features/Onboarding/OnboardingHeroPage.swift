//
//  OnboardingHeroPage.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct OnboardingHeroPage: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            LivingMeshBackground(palette: LivingMeshBackground.onboardingHero)

            VStack(alignment: .leading, spacing: 0) {
                Wordmark()
                    .padding(.top, 60)

                titleComposition
                    .padding(.top, 16)
                    .padding(.trailing, 40)

                Text("Identify plants instantly. Remember when to water them. Share your garden with anyone.")
                    .font(.fsCallout)
                    .lineSpacing(4)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 20)
                    .padding(.trailing, 40)

                Spacer()
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Spacer()

                Button(action: onContinue) {
                    Text("Get started")
                        .font(.fsHeadline)
                        .foregroundStyle(Palette.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white, in: .capsule)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var titleComposition: some View {
        Text("Your garden,\nin a \(Text("camera").font(.custom("NewYorkItalic", size: 44, relativeTo: .largeTitle))).")
            .font(.fsLargeTitle)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    OnboardingHeroPage(onContinue: {})
}
