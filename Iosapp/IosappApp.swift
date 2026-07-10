//
//  IosappApp.swift
//  Iosapp
//
//  Created by Aahan Jain on 7/9/26.
//

import SwiftUI
import SwiftData

@main
struct IosappApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [ClothingItem.self, Outfit.self, WishlistItem.self])
    }
}
