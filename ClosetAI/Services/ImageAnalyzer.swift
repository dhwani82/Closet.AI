//
//  ImageAnalyzer.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import Foundation
import UIKit
import Vision

enum ImageAnalyzer {
    /// On-device analysis: dominant color via pixel sampling, category via VNClassifyImageRequest.
    /// Best-effort — returns empty/nil when Vision can't determine something confidently.
    static func analyze(imageData: Data) async -> (dominantColorName: String, suggestedCategory: ClothingCategory?) {
        await Task.detached(priority: .userInitiated) {
            guard let uiImage = UIImage(data: imageData),
                  let cgImage = uiImage.cgImage else {
                return ("", nil)
            }

            let colorName = dominantColorName(from: cgImage)
            let category = suggestedCategory(from: cgImage, orientation: .init(uiImage.imageOrientation))
            return (colorName, category)
        }.value
    }

    // MARK: - Dominant color

    private static func dominantColorName(from cgImage: CGImage) -> String {
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return "" }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return ""
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Sample a grid of pixels for speed.
        let step = max(1, min(width, height) / 40)
        var votes: [String: Int] = [:]

        var y = 0
        while y < height {
            var x = 0
            while x < width {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(pixels[offset]) / 255
                let g = CGFloat(pixels[offset + 1]) / 255
                let b = CGFloat(pixels[offset + 2]) / 255
                let a = CGFloat(pixels[offset + 3]) / 255

                if a > 0.5, let name = colorName(red: r, green: g, blue: b) {
                    votes[name, default: 0] += 1
                }
                x += step
            }
            y += step
        }

        return votes.max(by: { $0.value < $1.value })?.key ?? ""
    }

    /// Maps RGB to a small set of wardrobe-friendly color names.
    private static func colorName(red: CGFloat, green: CGFloat, blue: CGFloat) -> String? {
        let color = UIColor(red: red, green: green, blue: blue, alpha: 1)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var v: CGFloat = 0
        guard color.getHue(&h, saturation: &s, brightness: &v, alpha: nil) else { return nil }

        if v < 0.15 { return "black" }
        if s < 0.12 {
            if v > 0.85 { return "white" }
            return "gray"
        }

        // Beige: muted warm tones
        if s < 0.4, v > 0.55, (h < 0.13 || h > 0.95) {
            return "beige"
        }

        // Brown: darker warm tones
        if v < 0.45, s > 0.15, h < 0.13 || h > 0.95 {
            return "brown"
        }

        switch h {
        case 0..<0.04, 0.92...1.0:
            return v > 0.7 && s < 0.55 ? "pink" : "red"
        case 0.04..<0.13:
            return v < 0.5 ? "brown" : "beige"
        case 0.13..<0.22:
            return "beige"
        case 0.22..<0.45:
            return "green"
        case 0.45..<0.58:
            return v < 0.4 ? "navy" : "blue"
        case 0.58..<0.75:
            return v < 0.35 ? "navy" : "blue"
        case 0.75..<0.92:
            return "pink"
        default:
            return nil
        }
    }

    // MARK: - Category

    private static func suggestedCategory(
        from cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) -> ClothingCategory? {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observations = request.results, !observations.isEmpty else {
            return nil
        }

        // Prefer higher-confidence labels that map to a wardrobe category.
        let minimumConfidence: Float = 0.25
        for observation in observations where observation.confidence >= minimumConfidence {
            if let category = mapLabel(observation.identifier) {
                return category
            }
        }
        return nil
    }

    private static func mapLabel(_ identifier: String) -> ClothingCategory? {
        let label = identifier.lowercased()

        let shoes: Set<String> = [
            "sneaker", "boot", "sandal", "high_heel", "footwear", "shoe", "shoes"
        ]
        let outerwear: Set<String> = [
            "jacket", "coat", "parka", "raincoat", "blazer", "suit"
        ]
        let tops: Set<String> = [
            "hoodie", "shirt", "tshirt", "t_shirt", "blouse", "sweater", "polo", "tank"
        ]
        let bottoms: Set<String> = [
            "jeans", "pants", "trousers", "shorts", "skirt", "legging", "leggings"
        ]
        let accessories: Set<String> = [
            "hat", "cap", "scarf", "glove", "jewelry", "watch", "bag", "backpack",
            "belt", "tie", "sock", "sunglasses", "eyeglasses"
        ]

        if shoes.contains(label) { return .shoes }
        if outerwear.contains(label) { return .outerwear }
        if tops.contains(label) { return .top }
        if bottoms.contains(label) { return .bottom }
        if accessories.contains(label) { return .accessory }

        // Partial matches for compound identifiers
        if label.contains("shoe") || label.contains("sneaker") || label.contains("boot") {
            return .shoes
        }
        if label.contains("jacket") || label.contains("coat") {
            return .outerwear
        }
        if label.contains("jean") || label.contains("pant") || label.contains("trouser") {
            return .bottom
        }
        if label.contains("shirt") || label.contains("hoodie") || label.contains("sweater") {
            return .top
        }

        return nil
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
