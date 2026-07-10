//
//  Outfit.swift
//  Iosapp
//

import Foundation
import SwiftData

@Model
final class Outfit {
    var id: UUID
    var name: String
    var itemIDs: [UUID]
    var aiReasoning: String
    var dateCreated: Date

    init(
        id: UUID = UUID(),
        name: String,
        itemIDs: [UUID] = [],
        aiReasoning: String = "",
        dateCreated: Date = .now
    ) {
        self.id = id
        self.name = name
        self.itemIDs = itemIDs
        self.aiReasoning = aiReasoning
        self.dateCreated = dateCreated
    }
}
