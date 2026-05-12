//
//  AddPlantFlow.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import SwiftData
import UIKit
import os

struct AddPlantFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var state: AddPlantState
    @State private var currentStep: Step
    @State private var showConfetti = false
    @State private var isSaving = false
    @State private var isIdentifying = false
    @State private var identifyTask: Task<Void, Never>?

    let prefilledFrom: ClassificationResult?
    let photoData: Data?

    init(prefilledFrom: ClassificationResult? = nil, photoData: Data? = nil) {
        self.prefilledFrom = prefilledFrom
        self.photoData = photoData
        let initialState = AddPlantState(
            scientificName: prefilledFrom?.scientificName ?? "",
            commonName: prefilledFrom?.commonName ?? "",
            familyName: prefilledFrom?.familyName,
            gbifID: prefilledFrom?.gbifID,
            photoData: photoData
        )
        _state = State(initialValue: initialState)

        if prefilledFrom != nil {
            // Coming from Identify tab — skip photo, go to confirm
            _currentStep = State(initialValue: .confirm)
        } else {
            // From "+" button — start with photo
            _currentStep = State(initialValue: .photo)
        }
    }

    enum Step: Int, CaseIterable {
        case photo, confirm, summary
        var index: Int { rawValue + 1 }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Palette.Dynamic.surfaceApp.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    progressDots
                        .padding(.top, Spacing.s4)
                        .padding(.bottom, Spacing.s6)

                    currentStepView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    bottomBar
                }
            }
            .navigationBarHidden(true)
            .interactiveDismissDisabled(state.photoData != nil)
            .task {
                // When coming from Identify tab with prefilled species, fetch care data
                if prefilledFrom != nil && state.careSource == nil && !state.isLoadingCare {
                    await state.fetchCareData()
                }
            }
            .overlay {
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(isFirstStep ? "Cancel" : "Back") {
                if isFirstStep {
                    identifyTask?.cancel()
                    dismiss()
                } else {
                    let prev = Step(rawValue: currentStep.rawValue - 1)
                    // Skip photo step backwards if coming from Identify tab
                    if prev == .photo && prefilledFrom != nil {
                        identifyTask?.cancel()
                        dismiss()
                    } else if let prev {
                        identifyTask?.cancel()
                        isIdentifying = false
                        withAnimation(.smooth) { currentStep = prev }
                    }
                }
            }
            .font(.fsCallout)
            .foregroundStyle(Palette.leaf700)

            Spacer()

            Text("\(visibleStepIndex)/\(visibleStepCount)")
                .font(.fsMonoCap)
                .tracking(0.4)
                .foregroundStyle(Palette.Dynamic.textTertiary)
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.top, Spacing.s3)
    }

    // MARK: - Progress

    private var isFirstStep: Bool {
        if prefilledFrom != nil { return currentStep == .confirm }
        return currentStep == .photo
    }

    private var visibleSteps: [Step] {
        if prefilledFrom != nil {
            return [.confirm, .summary]
        }
        return Step.allCases.map { $0 }
    }

    private var visibleStepIndex: Int {
        (visibleSteps.firstIndex(of: currentStep) ?? 0) + 1
    }

    private var visibleStepCount: Int {
        visibleSteps.count
    }

    private var progressDots: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(visibleSteps, id: \.self) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Palette.leaf700 : Palette.borderDefault)
                    .frame(width: 10, height: 10)
                    .animation(.smooth, value: currentStep)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var currentStepView: some View {
        Group {
            switch currentStep {
            case .photo:
                PhotoStepView(state: state)
            case .confirm:
                IdentifyStepView(state: state, isIdentifying: isIdentifying)
            case .summary:
                SummaryStepView(state: state)
            }
        }
        .id(currentStep)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        Group {
            if currentStep == .photo {
                Button("Next") {
                    autoIdentifyAndAdvance()
                }
                .fsButtonProminent()
                .frame(maxWidth: .infinity)
                .disabled(state.photoData == nil || isIdentifying)
                .opacity(state.photoData != nil && !isIdentifying ? 1.0 : 0.5)
            } else {
                Button(currentStep == .summary ? "Add to garden" : "Next") {
                    if currentStep == .summary {
                        save()
                    } else {
                        let next = Step(rawValue: currentStep.rawValue + 1)
                        if let next {
                            withAnimation(.smooth) { currentStep = next }
                        }
                    }
                }
                .fsButtonProminent()
                .frame(maxWidth: .infinity)
                .disabled(!state.isValid(for: currentStep) || isSaving)
                .opacity(state.isValid(for: currentStep) && !isSaving ? 1.0 : 0.5)
            }
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.bottom, Spacing.s6)
    }

    // MARK: - Auto-identify after photo

    private func autoIdentifyAndAdvance() {
        guard let photoData = state.photoData else { return }
        isIdentifying = true
        withAnimation(.smooth) { currentStep = .confirm }

        identifyTask = Task {
            // Run identification in background
            if let client = AppContainer.plantNetClient {
                do {
                    let candidates = try await client.identify(imageData: photoData, organ: "auto")
                    guard !Task.isCancelled else { return }
                    if let top = candidates.first {
                        state.scientificName = top.scientificName
                        state.commonName = top.preferredCommonName
                        state.familyName = top.familyName
                        state.gbifID = top.gbifID
                    }
                } catch {
                    // API failed — try local ML
                    Logger.network.debug("PlantNet failed in AddPlant: \(error.localizedDescription)")
                }
            }

            guard !Task.isCancelled else { return }

            // Also try local ML if API didn't fill
            if state.scientificName.isEmpty, let ciImage = CIImage(data: photoData) {
                let classifier = PlantClassifier()
                if let top = try? await classifier.classify(ciImage: ciImage, orientation: .up).first,
                   top.confidence > 0.3 {
                    let result = ClassificationResult.fromLocal(label: top.label, confidence: top.confidence)
                    state.scientificName = result.scientificName
                    state.commonName = result.commonName
                }
            }

            isIdentifying = false

            // Fetch species-specific care data from Perenual
            guard !Task.isCancelled else { return }
            await state.fetchCareData()
        }
    }

    // MARK: - Save

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        let plant = Plant(
            scientificName: state.scientificName,
            commonName: state.commonName,
            nickname: state.nickname
        )
        plant.locationLabel = state.location
        plant.familyName = state.familyName
        plant.plantNetGBIFID = state.gbifID
        plant.wateringIntervalDays = state.wateringIntervalDays
        plant.fertilizingIntervalDays = state.fertilizingIntervalDays
        plant.pruningMonths = state.pruningMonths

        if let photoData = state.photoData {
            let fileName = "\(plant.id.uuidString).jpg"
            if ImageStore.save(data: photoData, fileName: fileName) {
                let photo = PlantPhoto(fileName: fileName, isPrimary: true)
                plant.photos.append(photo)
            }
        }

        for task in CareScheduler.createDefaultTasks(for: plant) {
            plant.careTasks.append(task)
        }

        context.insert(plant)

        do {
            try context.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showConfetti = true
            let container = context.container
            let plantID = plant.id
            Task {
                let granted = await NotificationsManager.shared.requestAuthorizationIfNeeded()
                if granted {
                    await CareReminderScheduler.scheduleAll(for: plant)
                }
                try? await Task.sleep(for: .seconds(1.6))
                dismiss()
                let enrichContext = ModelContext(container)
                let descriptor = FetchDescriptor<Plant>(predicate: #Predicate { $0.id == plantID })
                if let saved = try? enrichContext.fetch(descriptor).first {
                    await PlantEnrichmentService.enrichIfNeeded(plant: saved, context: enrichContext)
                }
            }
        } catch {
            Logger.persistence.error("Failed to save plant: \(error.localizedDescription)")
        }
    }
}

// MARK: - AddPlantState

@Observable
final class AddPlantState {
    var scientificName: String
    var commonName: String
    var familyName: String?
    var gbifID: Int?
    var nickname: String = ""
    var location: String = ""
    var photoData: Data?
    var wateringIntervalDays: Int = 7
    var fertilizingIntervalDays: Int = 30
    var pruningMonths: [Int] = []
    var isLoadingCare = false
    var careSource: String?

    init(scientificName: String = "", commonName: String = "", familyName: String? = nil, gbifID: Int? = nil, photoData: Data? = nil) {
        self.scientificName = scientificName
        self.commonName = commonName
        self.familyName = familyName
        self.gbifID = gbifID
        self.photoData = photoData
    }

    func isValid(for step: AddPlantFlow.Step) -> Bool {
        switch step {
        case .photo: photoData != nil
        case .confirm: !scientificName.isEmpty
        case .summary: true
        }
    }

    /// Fetch species-specific care data from Perenual and pre-fill intervals.
    func fetchCareData() async {
        guard !scientificName.isEmpty else { return }
        guard let client = PerenualClient() else { return }

        isLoadingCare = true
        defer { isLoadingCare = false }

        do {
            let species = try await client.searchSpecies(query: scientificName)
            guard !Task.isCancelled, let match = species.first else { return }

            let care = try await client.careDetails(speciesID: match.id)
            guard !Task.isCancelled else { return }

            wateringIntervalDays = care.wateringFrequency.intervalDays
            if !care.pruningMonths.isEmpty {
                pruningMonths = care.pruningMonths
            }
            if care.careLevel?.lowercased() == "low" {
                fertilizingIntervalDays = 45
            } else if care.careLevel?.lowercased() == "high" {
                fertilizingIntervalDays = 14
            }
            careSource = "Perenual"
        } catch {
            // Keep defaults — non-fatal
        }
    }
}
