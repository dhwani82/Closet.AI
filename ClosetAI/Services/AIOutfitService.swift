//
//  AIOutfitService.swift
//  ClosetAI
//
//  Created by Dhwani Chauhan.
//

import Foundation

struct OutfitSuggestion: Codable, Identifiable, Equatable {
    var id: String { name + reasoning }
    let name: String
    let itemDescriptions: [String]
    let reasoning: String
    let missingItemSuggestion: String?
}

enum AIOutfitServiceError: LocalizedError, Equatable {
    case emptyCloset
    case missingAPIKey
    case invalidURL
    case networkFailure(underlying: Error)
    case badStatusCode(Int)
    case emptyResponse
    case decodeFailure(underlying: Error?)

    var errorDescription: String? {
        switch self {
        case .emptyCloset:
            return "Add a few pieces to your closet before generating outfits."
        case .missingAPIKey:
            return "Add your OpenAI API key in Config.swift to generate outfits."
        case .invalidURL:
            return "The AI API endpoint URL is invalid."
        case .networkFailure:
            return "Couldn't reach the AI service. Check your connection and try again."
        case .badStatusCode(let code):
            return "The AI service returned an error (status \(code))."
        case .emptyResponse:
            return "The AI service returned an empty response."
        case .decodeFailure:
            return "Couldn't understand the AI response. Try generating again."
        }
    }

    static func == (lhs: AIOutfitServiceError, rhs: AIOutfitServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.emptyCloset, .emptyCloset),
             (.missingAPIKey, .missingAPIKey),
             (.invalidURL, .invalidURL),
             (.emptyResponse, .emptyResponse),
             (.networkFailure, .networkFailure),
             (.decodeFailure, .decodeFailure):
            return true
        case (.badStatusCode(let a), .badStatusCode(let b)):
            return a == b
        default:
            return false
        }
    }
}

struct AIOutfitService {
    /// Easy to swap (e.g. "gpt-4o", "gpt-4o-mini").
    var model: String = "gpt-4o-mini"
    var maxTokens: Int = 2048

    func generateOutfits(from items: [ClothingItem]) async throws -> [OutfitSuggestion] {
        guard !items.isEmpty else {
            throw AIOutfitServiceError.emptyCloset
        }

        let apiKey = Config.aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else {
            throw AIOutfitServiceError.missingAPIKey
        }

        guard let url = URL(string: Config.aiAPIEndpoint) else {
            throw AIOutfitServiceError.invalidURL
        }

        let prompt = buildPrompt(items: items)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "response_format": ["type": "json_object"],
            "messages": [
                [
                    "role": "system",
                    "content": "You are a fashion stylist API. Always respond with valid JSON only."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw AIOutfitServiceError.decodeFailure(underlying: error)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIOutfitServiceError.networkFailure(underlying: error)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw AIOutfitServiceError.badStatusCode(http.statusCode)
        }

        let text = try extractAssistantText(from: data)
        return try decodeSuggestions(from: text)
    }

    // MARK: - Prompt

    private func buildPrompt(items: [ClothingItem]) -> String {
        let inventory = items.enumerated().map { index, item in
            let color = item.colorName.isEmpty ? "unknown color" : item.colorName
            let tags = item.tags.isEmpty ? "none" : item.tags.joined(separator: ", ")
            return "\(index + 1). \(item.category.displayName) — \(color) — tags: \(tags)"
        }.joined(separator: "\n")

        return """
        Given this wardrobe inventory, suggest 3 cohesive outfits.

        Closet inventory:
        \(inventory)

        Respond ONLY with JSON in this exact shape (no markdown):
        {
          "outfits": [
            {
              "name": "string",
              "itemDescriptions": ["string", "..."],
              "reasoning": "string",
              "missingItemSuggestion": "string or null"
            }
          ]
        }

        Rules:
        - itemDescriptions should reference pieces from the inventory in plain language (category + color).
        - reasoning should briefly explain why the outfit works.
        - missingItemSuggestion is optional: suggest one useful piece the user doesn't have, or null.
        """
    }

    // MARK: - Response parsing

    private struct OpenAIChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }
            let message: Message
        }
        let choices: [Choice]
    }

    private func extractAssistantText(from data: Data) throws -> String {
        if let decoded = try? JSONDecoder().decode(OpenAIChatResponse.self, from: data),
           let text = decoded.choices.first?.message.content?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            return text
        }

        guard let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            throw AIOutfitServiceError.emptyResponse
        }
        return raw
    }

    private func decodeSuggestions(from text: String) throws -> [OutfitSuggestion] {
        let jsonString = stripCodeFences(from: text)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIOutfitServiceError.decodeFailure(underlying: nil)
        }

        struct Wrapper: Decodable {
            let outfits: [OutfitSuggestion]
        }

        do {
            return try JSONDecoder().decode(Wrapper.self, from: jsonData).outfits
        } catch {
            // Fallback if the model returns a bare array.
            if let array = try? JSONDecoder().decode([OutfitSuggestion].self, from: jsonData) {
                return array
            }
            throw AIOutfitServiceError.decodeFailure(underlying: error)
        }
    }

    private func stripCodeFences(from text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            result = result
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }
}
