import Foundation

// Temporary mock implementation for testing
public actor MockOpenAIService: OpenAIServiceProtocol {
    public init() {}
    
    public func streamFeedback(imageData: Data) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            continuation.yield("Mock feedback response")
            continuation.finish()
        }
    }
    
    public func clearSession() {
        // Mock implementation
    }
}

// Non-actor wrapper for OpenAIServiceType
public class MockOpenAIServiceWrapper: OpenAIServiceType {
    private let service = MockOpenAIService()
    
    public init() {}
    
    public func streamFeedback(imageData: Data) async -> AsyncThrowingStream<String, Error> {
        return await service.streamFeedback(imageData: imageData)
    }
    
    public func clearSession() async {
        await service.clearSession()
    }
}