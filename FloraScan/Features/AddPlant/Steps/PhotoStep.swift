//
//  PhotoStep.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import PhotosUI
import UIKit
import os

struct PhotoStepView: View {
    @Bindable var state: AddPlantState
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    Text("A nice photo.")
                        .font(.fsTitle2)
                        .foregroundStyle(Palette.Dynamic.textPrimary)
                    Text("It will be the cover in your garden.")
                        .font(.fsFootnote)
                        .foregroundStyle(Palette.Dynamic.textSecondary)
                }

                // Photo preview
                if let data = state.photoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .clipShape(.rect(cornerRadius: Radius.cardLarge))
                        .fsShadow(2)
                } else {
                    RoundedRectangle(cornerRadius: Radius.cardLarge)
                        .fill(Palette.Dynamic.surfaceTinted)
                        .aspectRatio(4/3, contentMode: .fit)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.fsTitle1)
                                    .foregroundStyle(Palette.Dynamic.textTertiary)
                                Text("No photo")
                                    .font(.fsCaption1)
                                    .foregroundStyle(Palette.Dynamic.textTertiary)
                            }
                        }
                }

                // Action buttons
                VStack(spacing: Spacing.s3) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take photo", systemImage: "camera.fill")
                            .font(.fsCallout)
                    }
                    .buttonStyle(.plain)
                    .fsButtonProminent()
                    .frame(maxWidth: .infinity)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Choose from gallery", systemImage: "photo.on.rectangle")
                            .font(.fsCallout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.leaf700)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 22)
                    .frame(maxWidth: .infinity)
                    .background(Palette.Dynamic.surfaceTinted, in: Capsule())
                }
            }
            .padding(.horizontal, Spacing.s5)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   !data.isEmpty {
                    if let image = UIImage(data: data) {
                        let resized = image.resizedForAPI(maxDimension: 1920)
                        state.photoData = resized.jpegData(compressionQuality: 0.85) ?? data
                    } else {
                        state.photoData = data
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            AddPlantCameraView { data in
                state.photoData = data
            }
        }
    }
}

// MARK: - Custom Camera View for AddPlant (same controls as Identify tab)

private struct AddPlantCameraView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cameraSession = CameraSession()
    @State private var selectedOrgan: PlantOrgan = .auto
    @State private var isCapturing = false
    @State private var flashOpacity: Double = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    let onCapture: (Data) -> Void

    var body: some View {
        ZStack {
            // Camera preview
            switch cameraSession.status {
            case .running:
                CameraPreviewView(session: cameraSession.session)
                    .ignoresSafeArea()
            case .denied:
                Color.black.ignoresSafeArea()
                Text("Allow camera access in Settings")
                    .foregroundStyle(.white)
            case .failed(let msg):
                Color.black.ignoresSafeArea()
                Text(msg).foregroundStyle(.white)
            case .idle:
                Color.black.ignoresSafeArea()
                ProgressView().tint(.white)
            }

            if cameraSession.status == .running {
                // Top bar
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.fsTitle3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                        }
                        .glassed(in: .circle, interactive: true)

                        Spacer()
                    }
                    .padding(.horizontal, Spacing.s5)
                    .padding(.top, Spacing.s3)

                    Spacer()

                    // Hint
                    Text("Frame a leaf, flower or fruit")
                        .font(.fsCaption1)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.bottom, 12)

                    // Organ selector
                    OrganSelector(selected: $selectedOrgan)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                    // Shutter row: Gallery · Shutter · (placeholder)
                    HStack(spacing: 0) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.fsTitle3)
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                        .glassed(in: .circle, interactive: true)
                        .disabled(isCapturing)

                        Spacer()

                        PulsingShutterButton {
                            Task { await capture() }
                        }
                        .disabled(isCapturing)
                        .opacity(isCapturing ? 0.5 : 1.0)

                        Spacer()

                        Color.clear
                            .frame(width: 48, height: 48)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                }
            }

            // Flash overlay
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            Task { await cameraSession.start { _, _ in } }
        }
        .onDisappear {
            cameraSession.stop()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   !data.isEmpty {
                    if let image = UIImage(data: data) {
                        let resized = image.resizedForAPI(maxDimension: 1920)
                        onCapture(resized.jpegData(compressionQuality: 0.85) ?? data)
                    } else {
                        onCapture(data)
                    }
                    dismiss()
                }
            }
            selectedPhotoItem = nil
        }
    }

    private func capture() async {
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.easeOut(duration: 0.1)) { flashOpacity = 1 }
        try? await Task.sleep(for: .milliseconds(100))
        withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }

        let photoData = await cameraSession.capturePhotoData()
        guard let photoData else { return }

        if let image = UIImage(data: photoData) {
            let resized = image.resizedForAPI(maxDimension: 1920)
            onCapture(resized.jpegData(compressionQuality: 0.85) ?? photoData)
        } else {
            onCapture(photoData)
        }
        dismiss()
    }

}
