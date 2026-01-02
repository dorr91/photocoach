import Foundation

// Wrapper for ViewModels that need non-actor interface to OpenAIService
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