//
//  OutfitsView.swift
//  ClosetAI
//

import SwiftUI

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
}
