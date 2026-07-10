//
//  OutfitsView.swift
//  Iosapp
//

import SwiftUI
import SwiftData

struct OutfitsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Outfits coming soon",
                systemImage: "sparkles",
                description: Text("AI-generated outfit combinations from your closet will appear here.")
            )
            .navigationTitle("Outfits")
        }
    }
}

#Preview {
    OutfitsView()
        .modelContainer(for: [ClothingItem.self, Outfit.self, WishlistItem.self], inMemory: true)
}
