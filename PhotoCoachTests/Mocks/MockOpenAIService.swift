import Foundation
@testable import PhotoCoach

class MockOpenAIService: OpenAIServiceType {
    var mockStreamResponses: [String] = []
    var shouldThrowError: Error?
    var streamDelayMilliseconds: Int = 10
    var clearSessionCallCount = 0
    var streamFeedbackCallCount = 0
    var lastImageData: Data?
    
    func streamFeedback(imageData: Data) async -> AsyncThrowingStream<String, Error> {
        streamFeedbackCallCount += 1
        lastImageData = imageData
        
        return AsyncThrowingStream { continuation in
            Task {
                if let error = shouldThrowError {
                    continuation.finish(throwing: error)
                    return
                }
                
                for response in mockStreamResponses {
                    continuation.yield(response)
                    try? await Task.sleep(nanoseconds: UInt64(streamDelayMilliseconds) * 1_000_000)
                }
                
                continuation.finish()
            }
        }
    }
    
    func clearSession() async {
        clearSessionCallCount += 1
    }
    
    func reset() {
        mockStreamResponses = []
        shouldThrowError = nil
        streamDelayMilliseconds = 10
        clearSessionCallCount = 0
        streamFeedbackCallCount = 0
        lastImageData = nil
    }
}

extension MockOpenAIService {
    static func withSingleResponse(_ response: String) -> MockOpenAIService {
        let mock = MockOpenAIService()
        mock.mockStreamResponses = [response]
        return mock
    }
    
    static func withStreamedResponses(_ responses: [String]) -> MockOpenAIService {
        let mock = MockOpenAIService()
        mock.mockStreamResponses = responses
        return mock
    }
    
    static func withError(_ error: Error) -> MockOpenAIService {
        let mock = MockOpenAIService()
        mock.shouldThrowError = error
        return mock
    }
}