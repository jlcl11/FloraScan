//
//  IdentificationResultSheet.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI
import UIKit

struct IdentificationResultSheet: View {
    @Bindable var viewModel: IdentifyViewModel
    let onDismiss: () -> Void
    var onAddToGarden: ((ClassificationResult, Data?) -> Void)?

    @State private var isExpanded = false
    @State private var wikiSummary: String?

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .identifying:
                    loadingView
                case .results(let result):
                    resultsView(result)
                case .failed(let message):
                    failedView(message)
                case .idle:
                    loadingView
                }
            }
            .navigationTitle(viewModel.state.isIdentifying ? "Identifying…" : "Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: onDismiss)
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 24) {
            photoPreview
                .padding(.horizontal)

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Palette.leaf700)

                Text("Identifying plant…")
                    .font(.fsHeadline)
                    .foregroundStyle(Palette.Dynamic.textPrimary)

                Text("Analyzing with on-device AI and Pl@ntNet")
                    .font(.fsCaption1)
                    .foregroundStyle(Palette.Dynamic.textTertiary)
            }
            .padding(.top, Spacing.s4)

            Spacer()
        }
        .padding(.top, Spacing.s6)
    }

    // MARK: - Results (informational detail view)

    private func resultsView(_ result: ClassificationResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                photoPreview

                resultCard(result)

                // Care quick info
                careInfoSection(result)

                if let summary = wikiSummary {
                    descriptionSection(summary)
                }

                if !result.alternatives.isEmpty {
                    alternativesSection(result.alternatives)
                }

                if onAddToGarden != nil {
                    Button {
                        onAddToGarden?(result, viewModel.capturedPhoto)
                    } label: {
                        Label("Add to garden", systemImage: "leaf.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .fsButtonProminent()
                }
            }
            .padding()
            .padding(.bottom, 40)
        }
        .task(id: result.scientificName) {
            let client = WikipediaClient()
            wikiSummary = await client.summary(scientificName: result.scientificName)
        }
    }

    // MARK: - Care Info

    private func careInfoSection(_ result: ClassificationResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("ABOUT")
                .font(.fsMonoCap)
                .tracking(0.4)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            HStack(spacing: Spacing.s3) {
                infoChip(icon: "leaf.fill", text: result.scientificName, color: Palette.leaf500)
                if let family = result.familyName {
                    infoChip(icon: "tree.fill", text: family, color: Palette.carePruneSoft)
                }
            }

            if let source = sourceLabel(result.source) {
                HStack(spacing: 6) {
                    Image(systemName: result.source == .api ? "globe" : "cpu")
                        .font(.fsCaption2)
                    Text(source)
                        .font(.fsCaption1)
                }
                .foregroundStyle(Palette.Dynamic.textTertiary)
                .padding(.top, Spacing.s1)
            }
        }
        .padding(Spacing.s5)
        .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardMedium))
        .fsShadow(1)
    }

    private func infoChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.fsCaption2)
                .foregroundStyle(color)
            Text(text)
                .font(.fsCaption1)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
    }

    private func sourceLabel(_ source: ClassificationResult.Source) -> String? {
        switch source {
        case .api: "Identified with Pl@ntNet"
        case .local: "Identified with on-device model"
        case .none: nil
        }
    }

    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("DESCRIPTION")
                .font(.fsMonoCap)
                .tracking(0.4)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            Text(text)
                .font(.fsBody)
                .foregroundStyle(Palette.Dynamic.textSecondary)
                .lineLimit(isExpanded ? nil : 4)

            if text.count > 200 {
                Button(isExpanded ? "Show less" : "Show more") {
                    withAnimation(.smooth) { isExpanded.toggle() }
                }
                .font(.fsCaption1)
                .foregroundStyle(Palette.leaf700)
            }
        }
        .padding(Spacing.s5)
        .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardMedium))
        .fsShadow(1)
    }

    // MARK: - Failed

    private func failedView(_ message: String) -> some View {
        VStack(spacing: 24) {
            photoPreview
                .padding(.horizontal)

            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.fsDisplay)
                    .foregroundStyle(Palette.amber700)

                Text("Not identified")
                    .font(.fsTitle2)
                    .foregroundStyle(Palette.Dynamic.textPrimary)

                Text(message)
                    .font(.fsBody)
                    .foregroundStyle(Palette.Dynamic.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.s5)
            }
            .padding(.top, Spacing.s4)

            Button("Try again", action: onDismiss)
                .fsButtonProminent()
                .padding(.horizontal, Spacing.s5)

            Spacer()
        }
        .padding(.top, Spacing.s6)
    }

    // MARK: - Shared photo preview

    @ViewBuilder
    private var photoPreview: some View {
        if let photoData = viewModel.capturedPhoto, let img = UIImage(data: photoData) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: Radius.cardMedium))
        }
    }

    // MARK: - Result Card

    private func resultCard(_ result: ClassificationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.commonName)
                        .font(.fsTitle1)
                    Text(result.scientificName)
                        .font(.fsSciLarge)
                        .foregroundStyle(Palette.Dynamic.textSecondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(confidenceColor(result.confidence))
                        .frame(width: 6, height: 6)
                    Text("\(Int(result.confidence * 100))%")
                        .font(.fsCaption1)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(confidenceBackground(result.confidence), in: Capsule())
            }

            if let family = result.familyName {
                Text("Family \(family)")
                    .font(.fsFootnote)
                    .foregroundStyle(Palette.Dynamic.textTertiary)
            }

            HStack(spacing: 10) {
                ConfidenceBar(value: result.confidence)
                    .frame(height: 6)
                Text("\(Int(result.confidence * 100))%")
                    .font(.fsCaption1.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.Dynamic.textSecondary)
            }
        }
        .padding(Spacing.s5)
        .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardMedium))
        .fsShadow(1)
    }

    // MARK: - Alternatives

    private func alternativesSection(_ alternatives: [ClassificationResult.Alternative]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OR MAYBE…")
                .font(.fsMonoCap)
                .tracking(0.4)
                .foregroundStyle(Palette.Dynamic.textTertiary)

            ForEach(alternatives, id: \.scientificName) { alt in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alt.commonName)
                            .font(.fsSubhead)
                        Text(alt.scientificName)
                            .font(.fsSciSmall)
                            .foregroundStyle(Palette.Dynamic.textTertiary)
                    }
                    Spacer()
                    Text("\(Int(alt.confidence * 100))%")
                        .font(.fsCaption1)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        .foregroundStyle(Palette.Dynamic.textTertiary)
                }
                .padding(Spacing.s3)
                .background(Palette.Dynamic.surfaceCard, in: .rect(cornerRadius: Radius.cardSmall))
                .fsShadow(1)
            }
        }
    }

    // MARK: - Helpers

    private func confidenceColor(_ value: Double) -> Color {
        switch value {
        case 0.8...: Palette.leaf700
        case 0.4..<0.8: Palette.amber700
        default: Palette.clay700
        }
    }

    private func confidenceBackground(_ value: Double) -> Color {
        switch value {
        case 0.8...: Palette.leaf100
        case 0.4..<0.8: Palette.amber200
        default: Palette.clay200
        }
    }
}
