//
//  TodayOutfitStore.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import Foundation
import WidgetKit

/// Snapshot shared with the home-screen widget via App Group.
struct TodayOutfitSnapshot: Codable, Equatable {
    var name: String
    var pieces: [String]
    var reasoning: String
    var updatedAt: Date
}

enum AppGroup {
    static let id = "group.com.dchauha.ClosetAI"
    static let todayOutfitKey = "todayOutfitSnapshot"
}

enum TodayOutfitStore {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroup.id)
    }

    static func save(from suggestion: OutfitSuggestion) {
        let snapshot = TodayOutfitSnapshot(
            name: suggestion.name,
            pieces: suggestion.itemDescriptions,
            reasoning: suggestion.reasoning,
            updatedAt: .now
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: AppGroup.todayOutfitKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func load() -> TodayOutfitSnapshot? {
        guard let data = defaults?.data(forKey: AppGroup.todayOutfitKey) else { return nil }
        return try? JSONDecoder().decode(TodayOutfitSnapshot.self, from: data)
    }
}
