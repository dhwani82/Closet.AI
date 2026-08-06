//
//  SettingsView.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    Text("Closet.AI v0.1")
                    Text("Dhwani Chauhan")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
