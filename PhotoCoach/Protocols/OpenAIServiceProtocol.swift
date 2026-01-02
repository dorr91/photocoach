import Foundation

/// Result from streaming that includes the responseId for session continuity
struct StreamResult {
    let stream: AsyncThrowingStream<String, Error>
    let responseId: () async -> String?
}

protocol OpenAIServiceProtocol: Actor {
    func streamFeedback(imageData: Data, previousResponseId: String?) -> StreamResult
    func streamFollowup(question: String, previousResponseId: String) -> StreamResult
    func clearSession()
}

protocol OpenAIServiceType {
    func streamFeedback(imageData: Data, previousResponseId: String?) async -> StreamResult
    func streamFollowup(question: String, previousResponseId: String) async -> StreamResult
    func clearSession() async
}