import Foundation

enum OpenAIError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse
    case networkError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your OpenAI API key in Settings."
        case .invalidResponse:
            return "Invalid response from API."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return message
        }
    }
}

actor OpenAIService {
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    private let systemPrompt = """
    You are a photography teacher coaching a beginning photographer to improve their skills. Use a direct, technical tone to give feedback. Analyze the photo and provide actionable feedback.

    The student is taking photos on their phone, so focus on things they can control, like composition, lighting, and subject. Note phones control focus, exposure and white balance automatically.

    Be concise and specific in your feedback. Start with what works well, then give 2-3 specific improvements. Use plain language, not jargon. Keep response under 150 words.
    """

    func streamFeedback(imageData: Data) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let apiKey = KeychainHelper.getAPIKey() else {
                        throw OpenAIError.noAPIKey
                    }

                    let base64Image = imageData.base64EncodedString()

                    let requestBody: [String: Any] = [
                        "model": "gpt-4o",
                        "messages": [
                            [
                                "role": "system",
                                "content": systemPrompt
                            ],
                            [
                                "role": "user",
                                "content": [
                                    [
                                        "type": "text",
                                        "text": "Please analyze this photo and provide coaching feedback."
                                    ],
                                    [
                                        "type": "image_url",
                                        "image_url": [
                                            "url": "data:image/jpeg;base64,\(base64Image)"
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        "max_tokens": 500,
                        "stream": true
                    ]

                    var request = URLRequest(url: URL(string: baseURL)!)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw OpenAIError.invalidResponse
                    }

                    if httpResponse.statusCode != 200 {
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line
                        }
                        throw OpenAIError.apiError("API error (\(httpResponse.statusCode)): \(errorBody)")
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))

                        if jsonString == "[DONE]" {
                            break
                        }

                        guard let data = jsonString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let firstChoice = choices.first,
                              let delta = firstChoice["delta"] as? [String: Any],
                              let content = delta["content"] as? String else {
                            continue
                        }

                        continuation.yield(content)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
