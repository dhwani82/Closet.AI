//
//  WishlistItem.swift
//  Iosapp
//

import Foundation
import SwiftData

@Model
final class WishlistItem {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var itemDescription: String
    var estimatedPrice: Double
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        imageData: Data,
        itemDescription: String = "",
        estimatedPrice: Double = 0,
        dateAdded: Date = .now
    ) {
        self.id = id
        self.imageData = imageData
        self.itemDescription = itemDescription
        self.estimatedPrice = estimatedPrice
        self.dateAdded = dateAdded
    }
}
