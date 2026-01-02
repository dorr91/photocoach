import Foundation
@testable import PhotoCoach

class MockOpenAIService: OpenAIServiceType {
    var mockStreamResponses: [String] = []
    var shouldThrowError: Error?
    var streamDelayMilliseconds: Int = 10
    var clearSessionCallCount = 0
    var streamFeedbackCallCount = 0
    var streamFollowupCallCount = 0
    var lastImageData: Data?
    var lastFollowupQuestion: String?
    var lastPreviousResponseId: String?
    var mockFollowupResponses: [String] = []
    var mockResponseId: String? = "mock-response-id"

    func streamFeedback(imageData: Data, previousResponseId: String?) async -> StreamResult {
        streamFeedbackCallCount += 1
        lastImageData = imageData
        lastPreviousResponseId = previousResponseId

        let capturedResponseId = mockResponseId

        let stream = AsyncThrowingStream<String, Error> { continuation in
            Task {
                if let error = self.shouldThrowError {
                    continuation.finish(throwing: error)
                    return
                }

                for response in self.mockStreamResponses {
                    continuation.yield(response)
                    try? await Task.sleep(nanoseconds: UInt64(self.streamDelayMilliseconds) * 1_000_000)
                }

                continuation.finish()
            }
        }

        return StreamResult(stream: stream, responseId: { capturedResponseId })
    }

    func streamFollowup(question: String, previousResponseId: String) async -> StreamResult {
        streamFollowupCallCount += 1
        lastFollowupQuestion = question
        lastPreviousResponseId = previousResponseId

        let responses = mockFollowupResponses.isEmpty ? mockStreamResponses : mockFollowupResponses
        let capturedResponseId = mockResponseId

        let stream = AsyncThrowingStream<String, Error> { continuation in
            Task {
                if let error = self.shouldThrowError {
                    continuation.finish(throwing: error)
                    return
                }

                for response in responses {
                    continuation.yield(response)
                    try? await Task.sleep(nanoseconds: UInt64(self.streamDelayMilliseconds) * 1_000_000)
                }

                continuation.finish()
            }
        }

        return StreamResult(stream: stream, responseId: { capturedResponseId })
    }

    func clearSession() async {
        clearSessionCallCount += 1
    }

    func reset() {
        mockStreamResponses = []
        mockFollowupResponses = []
        shouldThrowError = nil
        streamDelayMilliseconds = 10
        clearSessionCallCount = 0
        streamFeedbackCallCount = 0
        streamFollowupCallCount = 0
        lastImageData = nil
        lastFollowupQuestion = nil
        lastPreviousResponseId = nil
        mockResponseId = "mock-response-id"
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
