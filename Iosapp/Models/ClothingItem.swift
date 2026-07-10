//
//  ClothingItem.swift
//  Iosapp
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case top
    case bottom
    case shoes
    case outerwear
    case accessory

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .top: "Top"
        case .bottom: "Bottom"
        case .shoes: "Shoes"
        case .outerwear: "Outerwear"
        case .accessory: "Accessory"
        }
    }

    var iconName: String {
        switch self {
        case .top: "tshirt"
        case .bottom: "figure.walk"
        case .shoes: "shoe.fill"
        case .outerwear: "jacket"
        case .accessory: "eyeglasses"
        }
    }
}

@Model
final class ClothingItem {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var category: ClothingCategory
    var colorName: String
    var tags: [String]
    var dateAdded: Date

    var uiImage: Image? {
        guard let uiImage = UIImage(data: imageData) else { return nil }
        return Image(uiImage: uiImage)
    }

    init(
        id: UUID = UUID(),
        imageData: Data,
        category: ClothingCategory = .top,
        colorName: String = "",
        tags: [String] = [],
        dateAdded: Date = .now
    ) {
        self.id = id
        self.imageData = imageData
        self.category = category
        self.colorName = colorName
        self.tags = tags
        self.dateAdded = dateAdded
    }
}
