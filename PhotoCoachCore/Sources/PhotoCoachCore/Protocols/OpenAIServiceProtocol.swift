import Foundation

public protocol OpenAIServiceProtocol: Actor {
    func streamFeedback(imageData: Data) -> AsyncThrowingStream<String, Error>
    func clearSession()
}

public protocol OpenAIServiceType {
    func streamFeedback(imageData: Data) async -> AsyncThrowingStream<String, Error>
    func clearSession() async
}