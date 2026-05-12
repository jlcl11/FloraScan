//
//  OnboardingPrivacyPage.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct OnboardingPrivacyPage: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            LivingMeshBackground(palette: LivingMeshBackground.nature)

            VStack(alignment: .leading, spacing: 0) {
                Wordmark()
                    .padding(.top, 60)

                Text("Your \(Text("privacy").font(.custom("NewYorkItalic", size: 34, relativeTo: .largeTitle))), first.")
                    .font(.fsLargeTitle)
                    .foregroundStyle(.white)
                    .padding(.top, 16)
                    .padding(.trailing, 40)

                Text("Your garden is stored only on your iPhone. Photos are securely sent to Pl@ntNet for identification and never stored on servers.")
                    .font(.fsCallout)
                    .lineSpacing(4)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 20)
                    .padding(.trailing, 40)

                Text("▪ Local data  ▪ No accounts  ▪ No tracking")
                    .font(.fsFootnote)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, 20)

                Spacer()
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Spacer()

                Button(action: onContinue) {
                    Text("Continue")
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
}

#Preview {
    OnboardingPrivacyPage(onContinue: {})
}
