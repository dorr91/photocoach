import Foundation

protocol OpenAIServiceProtocol: Actor {
    func streamFeedback(imageData: Data) -> AsyncThrowingStream<String, Error>
    func clearSession()
}

protocol OpenAIServiceType {
    func streamFeedback(imageData: Data) async -> AsyncThrowingStream<String, Error>
    func clearSession() async
}