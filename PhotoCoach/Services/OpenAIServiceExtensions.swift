import Foundation

// This extension provides a non-actor interface for OpenAIService
// to support dependency injection in ViewModels
extension OpenAIService: OpenAIServiceType {
    nonisolated func streamFeedback(imageData: Data) async -> AsyncThrowingStream<String, Error> {
        await self.streamFeedback(imageData: imageData)
    }
    
    nonisolated func clearSession() async {
        await self.clearSession()
    }
}

// Convenience wrapper for ViewModels that need non-actor interface
class OpenAIServiceWrapper: OpenAIServiceType {
    private let service: OpenAIService
    
    init(service: OpenAIService) {
        self.service = service
    }
    
    func streamFeedback(imageData: Data) async -> AsyncThrowingStream<String, Error> {
        await service.streamFeedback(imageData: imageData)
    }
    
    func clearSession() async {
        await service.clearSession()
    }
}