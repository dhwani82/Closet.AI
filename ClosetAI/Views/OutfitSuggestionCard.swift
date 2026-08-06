//
//  OutfitSuggestionCard.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import SwiftUI

struct OutfitSuggestionCard: View {
    let suggestion: OutfitSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: Constants.Spacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.tint)
                Text(suggestion.name)
                    .font(.headline)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: Constants.Spacing.xs + 2) {
                Label("Pieces", systemImage: "hanger")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(suggestion.itemDescriptions, id: \.self) { description in
                    Text("• \(description)")
                        .font(.subheadline)
                }
            }

            Text(suggestion.reasoning)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let missing = suggestion.missingItemSuggestion,
               !missing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(alignment: .top, spacing: Constants.Spacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text("You're missing: \(missing)")
                        .font(.subheadline.weight(.medium))
                }
                .padding(Constants.Spacing.sm + 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    .orange.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: Constants.CornerRadius.small, style: .continuous)
                )
            }
        }
        .padding(Constants.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .fill.tertiary,
            in: RoundedRectangle(cornerRadius: Constants.CornerRadius.large, style: .continuous)
        )
    }
}

#Preview {
    OutfitSuggestionCard(
        suggestion: OutfitSuggestion(
            name: "Casual Friday",
            itemDescriptions: ["Navy top", "Gray bottom", "White sneakers"],
            reasoning: "Clean contrast with a relaxed silhouette.",
            missingItemSuggestion: "A light denim jacket"
        )
    )
    .padding()
}
