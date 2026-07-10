//
//  WishlistView.swift
//  Iosapp
//

import SwiftUI
import SwiftData

struct WishlistView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Wishlist coming soon",
                systemImage: "heart",
                description: Text("Snap a photo of items you want to track them here.")
            )
            .navigationTitle("Wishlist")
        }
    }
}

#Preview {
    WishlistView()
        .modelContainer(for: [ClothingItem.self, Outfit.self, WishlistItem.self], inMemory: true)
}
