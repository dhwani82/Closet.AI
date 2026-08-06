//
//  ItemDescriptionService.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import Foundation
import UIKit

enum ItemDescriptionServiceError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidImage
    case networkFailure(underlying: Error)
    case badStatusCode(Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add your OpenAI API key in Config.swift to describe items."
        case .invalidURL:
            return "The AI API endpoint URL is invalid."
        case .invalidImage:
            return "Couldn't prepare that photo for description."
        case .networkFailure:
            return "Couldn't reach the AI service. Check your connection and try again."
        case .badStatusCode(let code):
            return "The AI service returned an error (status \(code))."
        case .emptyResponse:
            return "The AI service returned an empty description."
        }
    }
}

struct ItemDescriptionService {
    var model: String = "gpt-4o-mini"
    var maxTokens: Int = 80

    func describeItem(imageData: Data) async throws -> String {
        let apiKey = Config.aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else {
            throw ItemDescriptionServiceError.missingAPIKey
        }

        guard let url = URL(string: Config.aiAPIEndpoint) else {
            throw ItemDescriptionServiceError.invalidURL
        }

        // Downscale slightly so the vision request stays light.
        guard let uiImage = UIImage(data: imageData),
              let jpeg = uiImage.jpegData(compressionQuality: 0.6) else {
            throw ItemDescriptionServiceError.invalidImage
        }

        let base64 = jpeg.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": """
                            Describe this clothing or fashion item in one short sentence \
                            for a wishlist (e.g. "Navy wool blazer with gold buttons"). \
                            Mention color, garment type, and one notable detail if visible. \
                            Respond with plain text only — no quotes or markdown.
                            """
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": dataURL,
                                "detail": "low"
                            ]
                        ]
                    ]
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw ItemDescriptionServiceError.invalidImage
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ItemDescriptionServiceError.networkFailure(underlying: error)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ItemDescriptionServiceError.badStatusCode(http.statusCode)
        }

        struct OpenAIChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String?
                }
                let message: Message
            }
            let choices: [Choice]
        }

        guard let decoded = try? JSONDecoder().decode(OpenAIChatResponse.self, from: data),
              let text = decoded.choices.first?.message.content?
                .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\""))),
              !text.isEmpty else {
            throw ItemDescriptionServiceError.emptyResponse
        }

        return text
    }
}
