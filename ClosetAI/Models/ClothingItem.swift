//
//  ClothingItem.swift
//  ClosetAI
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
        case .top: return "Top"
        case .bottom: return "Bottom"
        case .shoes: return "Shoes"
        case .outerwear: return "Outerwear"
        case .accessory: return "Accessory"
        }
    }

    var iconName: String {
        switch self {
        case .top: return "tshirt"
        case .bottom: return "figure.walk"
        case .shoes: return "shoe.fill"
        case .outerwear: return "jacket"
        case .accessory: return "eyeglasses"
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

    var uiImage: Image {
        if let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }

    init(
        id: UUID = UUID(),
        imageData: Data,
        category: ClothingCategory,
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
