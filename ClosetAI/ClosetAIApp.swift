//
//  ClosetAIApp.swift
//  ClosetAI
//
//  Created by Aahan Jain on 7/11/26.
//

import SwiftUI
import SwiftData

@main
struct ClosetAIApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [ClothingItem.self, Outfit.self, WishlistItem.self])
    }
}
