//
//  IdentifyView.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import PhotosUI
import CoreImage
import UIKit

struct IdentifyView: View {
    @State private var viewModel = IdentifyViewModel(plantNet: AppContainer.plantNetClient)
    @State private var cameraSession = CameraSession()
    @State private var selectedOrgan: PlantOrgan = .auto
    @State private var flashOpacity: Double = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isCapturing = false
    @State private var identifyTask: Task<Void, Never>?
    @State private var addPlantResult: ClassificationResult?
    @State private var addPlantPhoto: Data?
    @State private var showAddPlantFlow = false

    private let throttler = FrameThrottler(framesPerSecond: 5)

    var body: some View {
        ZStack {
            // Layer 0: Camera preview
            switch cameraSession.status {
            case .running:
                CameraPreviewView(session: cameraSession.session)
                    .ignoresSafeArea()
            case .denied:
                deniedView
            case .failed(let msg):
                failedView(msg)
            case .idle:
                Color.black.ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }

            // Layer 1: Top status chip
            if cameraSession.status == .running {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                        Text("Frame and capture")
                            .font(.fsCaption1)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassed(in: .capsule, tint: Palette.primary.opacity(0.5))
                    Spacer()
                }
                .padding(.top, 60)
            }

            // Layer 2: Bottom controls
            if cameraSession.status == .running {
                VStack {
                    Spacer()

                    // Hint text
                    Text(hintText)
                        .font(.fsCaption1)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.bottom, 12)

                    OrganSelector(selected: $selectedOrgan)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                    // Shutter row: Gallery · Shutter · (placeholder)
                    HStack(spacing: 0) {
                        // Gallery button
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

                        // Shutter — disabled while capturing to prevent double-tap crash
                        PulsingShutterButton {
                            Task { await capture() }
                        }
                        .disabled(isCapturing)
                        .opacity(isCapturing ? 0.5 : 1.0)

                        Spacer()

                        // Placeholder for symmetry
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
            Task { await setupCamera() }
        }
        .onDisappear {
            cameraSession.stop()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { await identifyFromGallery(item: newItem) }
            selectedPhotoItem = nil
        }
        .sheet(isPresented: $viewModel.showResultSheet, onDismiss: {
            identifyTask?.cancel()
            identifyTask = nil
            viewModel.reset()
            if addPlantResult != nil {
                showAddPlantFlow = true
            }
        }) {
            IdentificationResultSheet(
                viewModel: viewModel,
                onDismiss: {
                    viewModel.reset()
                },
                onAddToGarden: { result, photo in
                    addPlantResult = result
                    addPlantPhoto = photo
                    viewModel.reset()
                }
            )
        }
        .fullScreenCover(isPresented: $showAddPlantFlow, onDismiss: {
            addPlantResult = nil
            addPlantPhoto = nil
        }) {
            AddPlantFlow(
                prefilledFrom: addPlantResult,
                photoData: addPlantPhoto
            )
        }
    }

    // MARK: - Camera Setup

    private func setupCamera() async {
        // Live classification disabled — current local model (Oxford 102) is a generic
        // image classifier, not a plant identifier. It produces labels like "Desk", "Pot"
        // which are confusing. Re-enable when a proper plant model is integrated.
        await cameraSession.start { _, _ in }
    }

    // MARK: - Capture from camera

    private func capture() async {
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.easeOut(duration: 0.1)) { flashOpacity = 1 }
        try? await Task.sleep(for: .milliseconds(100))
        withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }

        let photoData = await cameraSession.capturePhotoData()
        guard let photoData else {
            viewModel.fail(message: "Could not capture the photo. Please try again.")
            return
        }

        guard let ciImage = CIImage(data: photoData) else {
            viewModel.fail(message: "The captured image is not valid.")
            return
        }
        identifyTask = Task {
            await viewModel.identify(
                imageData: photoData,
                ciImage: ciImage,
                organ: selectedOrgan.rawValue
            )
        }
    }

    // MARK: - Identify from gallery

    private func identifyFromGallery(item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              !data.isEmpty else { return }

        let jpegData: Data
        if let uiImage = UIImage(data: data) {
            // Resize to max 1920px on longest side — prevents API rejection on large sensors
            let resized = uiImage.resizedForAPI(maxDimension: 1920)
            jpegData = resized.jpegData(compressionQuality: 0.85) ?? data
        } else {
            jpegData = data
        }

        guard let ciImage = CIImage(data: jpegData) else {
            viewModel.fail(message: "The selected image is not valid.")
            return
        }
        identifyTask = Task {
            await viewModel.identify(
                imageData: jpegData,
                ciImage: ciImage,
                organ: selectedOrgan.rawValue
            )
        }
    }

    // MARK: - Helpers

    private let hintText = "Frame a leaf, flower or fruit"

    // MARK: - Fallback Views

    private var deniedView: some View {
        ZStack {
            LivingMeshBackground(palette: LivingMeshBackground.nature)
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                Text("Camera not available")
                    .font(.fsTitle2)
                    .foregroundStyle(.white)
                Text("Enable camera access in Settings to identify plants.")
                    .font(.fsSubhead)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Go to Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .fsButtonProminent()
                .padding(.top, 16)
            }
        }
    }

    private func failedView(_ msg: String) -> some View {
        ContentUnavailableView(
            "Camera error",
            systemImage: "exclamationmark.triangle.fill",
            description: Text(msg)
        )
    }
}

#Preview {
    IdentifyView()
}
