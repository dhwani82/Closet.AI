//
//  TodayOutfitSnapshot.swift
//  ClosetAIWidget
//
//  Created by Dhwani Chauhan.
//
//  Mirrors ClosetAI/Services/TodayOutfitStore snapshot + App Group keys.
//

import Foundation

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

    static func load() -> TodayOutfitSnapshot? {
        guard let data = defaults?.data(forKey: AppGroup.todayOutfitKey) else { return nil }
        return try? JSONDecoder().decode(TodayOutfitSnapshot.self, from: data)
    }
}
