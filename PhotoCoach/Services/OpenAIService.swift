import Foundation

enum OpenAIError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse
    case networkError(Error)
    case apiError(String)
    case noSessionContext

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
        case .noSessionContext:
            return "No previous photo context available. Please analyze a photo first."
        }
    }
}

actor OpenAIService: OpenAIServiceProtocol {
    private let urlSession: URLSessionProtocol
    private let keychainService: KeychainServiceProtocol

    private let baseURL = "https://api.openai.com/v1/responses"

    private let instructions = """
    You're a professional photographer helping teach a new photographer the craft.

    Guidelines:
    - The photographer is using a phone camera, which handles focus, exposure, and white balance automatically. Focus on composition, lighting, timing, subject choice, and anything else a smartphone photographer can control.
    - When you use new jargon, briefly explain it.
    - If patterns appear across photos, mention them to reinforce learning.

    Analyze this photo and provide feedback. What's good about it? What could be improved?

    Include a summary of your feedback. The summary should be 1-2 sentences plus bullets for each suggestion (if any).
    """

    // Captured response ID from the last completed request
    private var lastCapturedResponseId: String?

    init(urlSession: URLSessionProtocol = URLSession.shared,
         keychainService: KeychainServiceProtocol) {
        self.urlSession = urlSession
        self.keychainService = keychainService
    }

    func clearSession() {
        lastCapturedResponseId = nil
    }

    func streamFeedback(imageData: Data, previousResponseId: String?) -> StreamResult {
        // Use a class to capture the response ID across the async boundary
        let capturedId = ResponseIdCapture()

        let stream = AsyncThrowingStream<String, Error> { continuation in
            Task {
                do {
                    guard let apiKey = self.keychainService.getAPIKey() else {
                        throw OpenAIError.noAPIKey
                    }

                    let base64Image = imageData.base64EncodedString()

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
                        "max_output_tokens": 1500,
                        "store": true,
                        "stream": true
                    ]

                    if let prevId = previousResponseId {
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
                        if capturedId.value == nil, let responseId = json["id"] as? String {
                            capturedId.value = responseId
                            self.lastCapturedResponseId = responseId
                        }

                        // Extract text delta from streaming response
                        if let delta = json["delta"] as? String {
                            continuation.yield(delta)
                        } else if let output = json["output"] as? [[String: Any]] {
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

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

        return StreamResult(stream: stream, responseId: { capturedId.value })
    }

    func streamFollowup(question: String, previousResponseId: String) -> StreamResult {
        let capturedId = ResponseIdCapture()

        let stream = AsyncThrowingStream<String, Error> { continuation in
            Task {
                do {
                    guard let apiKey = self.keychainService.getAPIKey() else {
                        throw OpenAIError.noAPIKey
                    }

                    let input: [[String: Any]] = [
                        [
                            "role": "user",
                            "content": [
                                [
                                    "type": "input_text",
                                    "text": question
                                ]
                            ]
                        ]
                    ]

                    let requestBody: [String: Any] = [
                        "model": "gpt-4o",
                        "instructions": self.instructions,
                        "input": input,
                        "max_output_tokens": 1500,
                        "store": true,
                        "stream": true,
                        "previous_response_id": previousResponseId
                    ]

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

                        if capturedId.value == nil, let responseId = json["id"] as? String {
                            capturedId.value = responseId
                            self.lastCapturedResponseId = responseId
                        }

                        if let delta = json["delta"] as? String {
                            continuation.yield(delta)
                        } else if let output = json["output"] as? [[String: Any]] {
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

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

        return StreamResult(stream: stream, responseId: { capturedId.value })
    }
}

// Helper class to capture response ID across async boundaries
private final class ResponseIdCapture: @unchecked Sendable {
    var value: String?
}
