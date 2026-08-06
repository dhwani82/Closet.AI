//
//  ClosetAIApp.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import SwiftUI
import SwiftData

@main
struct ClosetAIApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    RootTabView()
                } else {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                }
            }
        }
        .modelContainer(for: [ClothingItem.self, Outfit.self, WishlistItem.self])
    }
}
