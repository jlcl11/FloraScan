//
//  OnboardingCameraPermissionPage.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import AVFoundation

struct OnboardingCameraPermissionPage: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack(alignment: .topLeading) {
            LivingMeshBackground(palette: LivingMeshBackground.nature)

            VStack(alignment: .leading, spacing: 0) {
                Wordmark()
                    .padding(.top, 60)

                Text("Camera access.")
                    .font(.fsLargeTitle)
                    .foregroundStyle(.white)
                    .padding(.top, 16)
                    .padding(.trailing, 40)

                Text("FloraScan uses your camera to identify plants instantly. Photos are securely sent to Pl@ntNet and are never stored.")
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

                Button {
                    Task {
                        _ = await AVCaptureDevice.requestAccess(for: .video)
                        onComplete()
                    }
                } label: {
                    Text("Allow camera")
                        .font(.fsHeadline)
                        .foregroundStyle(Palette.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white, in: .capsule)
                }
                .buttonStyle(.plain)

                if reduceTransparency {
                    Button(action: onComplete) {
                        Text("Later")
                            .font(.fsCallout)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.regularMaterial, in: .capsule)
                            .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: onComplete) {
                        Text("Later")
                            .font(.fsCallout)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .buttonStyle(.plain)
                    .glassed(in: .capsule, interactive: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingCameraPermissionPage(onComplete: {})
}
