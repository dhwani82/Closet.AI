//
//  RootTabView.swift
//  Iosapp
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            ClosetView()
                .tabItem {
                    Label("Closet", systemImage: "tshirt.fill")
                }

            OutfitsView()
                .tabItem {
                    Label("Outfits", systemImage: "person.crop.rectangle.stack.fill")
                }

            WishlistView()
                .tabItem {
                    Label("Wishlist", systemImage: "heart.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [ClothingItem.self, Outfit.self, WishlistItem.self], inMemory: true)
}
