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

actor OpenAIService: OpenAIServiceProtocol {
    private let urlSession: URLSessionProtocol
    private let keychainService: KeychainServiceProtocol

    private let baseURL = "https://api.openai.com/v1/responses"

    private let instructions = """
    You are a photography coach helping a beginner improve their skills in real-time. They're on a photo expedition with their phone.

    Structure your feedback:
    1. **What works** - One sentence on the strongest element of this photo.
    2. **Principle** - Name one photography principle they should remember (e.g., leading lines, fill the frame, light direction, rule of thirds, background separation). Explain it in one sentence.
    3. **Reshoot suggestion** (optional) - Only if there's a clear, meaningful improvement: give a specific physical instruction like "step 3 feet left", "crouch down", "move closer to fill the frame", or "wait for the person to exit". Skip this if the photo is already solid or the moment can't be recreated.

    Guidelines:
    - Phone cameras handle focus, exposure, and white balance automatically. Focus on composition, lighting, timing, and subject.
    - Be direct and specific. Use plain language, not jargon.
    - Aim for around 250 words, but up to 500 if more depth is helpful.
    - If you've given reshoot advice in this session, don't contradict it.
    - If patterns appear across photos, mention them briefly.
    """

    // Store the last response ID for conversation continuity
    private var previousResponseId: String?
    
    init(urlSession: URLSessionProtocol = URLSession.shared,
         keychainService: KeychainServiceProtocol) {
        self.urlSession = urlSession
        self.keychainService = keychainService
    }

    func clearSession() {
        previousResponseId = nil
    }

    func streamFeedback(imageData: Data) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let apiKey = self.keychainService.getAPIKey() else {
                        throw OpenAIError.noAPIKey
                    }

                    let base64Image = imageData.base64EncodedString()

                    // Build input with image
                    let input: [[String: Any]] = [
                        [
                            "role": "user",
                            "content": [
                                [
                                    "type": "input_text",
                                    "text": "Please analyze this photo and provide coaching feedback."
                                ],
                                [
                                    "type": "input_image",
                                    "image_url": "data:image/jpeg;base64,\(base64Image)"
                                ]
                            ]
                        ]
                    ]

                    var requestBody: [String: Any] = [
                        "model": "gpt-4o",
                        "instructions": self.instructions,
                        "input": input,
                        "max_output_tokens": 500,
                        "store": true,
                        "stream": true
                    ]

                    // Chain to previous response if we have one
                    if let prevId = self.previousResponseId {
                        requestBody["previous_response_id"] = prevId
                    }

                    var request = URLRequest(url: URL(string: self.baseURL)!)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                    let (bytes, response) = try await self.urlSession.bytes(for: request)

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

                    var capturedResponseId: String?

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))

                        if jsonString == "[DONE]" {
                            break
                        }

                        guard let data = jsonString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                            continue
                        }

                        // Capture the response ID from the first event
                        if capturedResponseId == nil, let responseId = json["id"] as? String {
                            capturedResponseId = responseId
                        }

                        // Extract text delta from streaming response
                        if let delta = json["delta"] as? String {
                            continuation.yield(delta)
                        } else if let output = json["output"] as? [[String: Any]] {
                            // Handle output array format
                            for item in output {
                                if let content = item["content"] as? [[String: Any]] {
                                    for contentItem in content {
                                        if let text = contentItem["text"] as? String {
                                            continuation.yield(text)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Store the response ID for next call
                    if let responseId = capturedResponseId {
                        self.previousResponseId = responseId
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
