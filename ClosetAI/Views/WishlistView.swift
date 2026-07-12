//
//  WishlistView.swift
//  ClosetAI
//

import SwiftUI

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
}
