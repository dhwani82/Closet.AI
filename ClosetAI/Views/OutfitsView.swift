//
//  OutfitsView.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import SwiftUI
import SwiftData

struct OutfitsView: View {
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var closetItems: [ClothingItem]

    @State private var suggestions: [OutfitSuggestion] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private let service = AIOutfitService()

    var body: some View {
        NavigationStack {
            Group {
                if isGenerating && suggestions.isEmpty {
                    loadingState
                } else if let errorMessage, suggestions.isEmpty {
                    errorState(message: errorMessage)
                } else if suggestions.isEmpty {
                    emptyState
                } else {
                    suggestionsList
                }
            }
            .navigationTitle("Outfits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !suggestions.isEmpty {
                        Button {
                            Task { await generate() }
                        } label: {
                            if isGenerating {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(isGenerating || closetItems.isEmpty)
                        .accessibilityLabel("Generate outfits")
                    }
                }
            }
        }
    }

    // MARK: - States

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No outfits yet", systemImage: "sparkles")
        } description: {
            Text("Generate AI outfit combinations from the clothes in your closet.")
        } actions: {
            Button {
                Task { await generate() }
            } label: {
                Label("Generate outfits", systemImage: "wand.and.stars")
            }
            .buttonStyle(.borderedProminent)
            .disabled(closetItems.isEmpty)
        }
    }

    private var loadingState: some View {
        VStack(spacing: Constants.Spacing.lg) {
            ProgressView()
            Text("Styling your closet…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn't generate outfits", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button {
                Task { await generate() }
            } label: {
                Label("Try again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var suggestionsList: some View {
        ScrollView {
            LazyVStack(spacing: Constants.Spacing.lg) {
                if let errorMessage {
                    HStack(alignment: .top, spacing: Constants.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(errorMessage)
                            .font(.subheadline)
                        Spacer(minLength: 0)
                    }
                    .padding(Constants.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        .orange.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Constants.CornerRadius.medium, style: .continuous)
                    )
                }

                ForEach(suggestions) { suggestion in
                    OutfitSuggestionCard(suggestion: suggestion)
                }

                Button {
                    Task { await generate() }
                } label: {
                    Label("Generate again", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating)
            }
            .padding(Constants.Spacing.lg)
        }
    }

    // MARK: - Actions

    @MainActor
    private func generate() async {
        errorMessage = nil
        isGenerating = true
        defer { isGenerating = false }

        do {
            suggestions = try await service.generateOutfits(from: closetItems)
            if let today = suggestions.first {
                TodayOutfitStore.save(from: today)
            }
        } catch let error as AIOutfitServiceError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}

#Preview {
    OutfitsView()
        .modelContainer(
            for: [ClothingItem.self, Outfit.self, WishlistItem.self],
            inMemory: true
        )
}
