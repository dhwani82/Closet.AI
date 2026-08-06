//
//  OnboardingView.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        (
            "tshirt.fill",
            "Build your digital closet",
            "Photograph your clothes and keep them organized by category and color."
        ),
        (
            "sparkles",
            "Get AI outfit ideas",
            "Generate outfit combinations from what you already own — tailored to your wardrobe."
        ),
        (
            "heart.fill",
            "Track what you want",
            "Save wishlist finds with a photo, description, and estimated price."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, pageContent in
                    VStack(spacing: Constants.Spacing.xl) {
                        Spacer()

                        Image(systemName: pageContent.symbol)
                            .font(.system(size: 56, weight: .medium))
                            .foregroundStyle(.tint)
                            .symbolRenderingMode(.hierarchical)

                        VStack(spacing: Constants.Spacing.md) {
                            Text(pageContent.title)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)

                            Text(pageContent.body)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Constants.Spacing.xl)
                        }

                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Get started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Constants.Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, Constants.Spacing.lg)
            .padding(.bottom, Constants.Spacing.xl)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
