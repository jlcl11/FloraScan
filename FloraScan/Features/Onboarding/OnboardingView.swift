//
//  OnboardingView.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var currentPage: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardingHeroPage(onContinue: { advance() })
                .tag(0)

                OnboardingPrivacyPage(onContinue: { advance() })
                    .tag(1)

                OnboardingCameraPermissionPage(onComplete: { hasOnboarded = true })
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            PageIndicator(totalPages: 3, currentPage: currentPage)
                .padding(.bottom, 100)
        }
    }

    private func advance() {
        withAnimation(.smooth(duration: 0.4)) {
            currentPage += 1
        }
    }
}

#Preview {
    OnboardingView()
}
