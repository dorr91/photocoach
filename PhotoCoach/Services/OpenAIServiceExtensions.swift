import Foundation

// Wrapper for ViewModels that need non-actor interface to OpenAIService
class OpenAIServiceWrapper: OpenAIServiceType {
    private let service: OpenAIService

    init(service: OpenAIService) {
        self.service = service
    }

    func streamFeedback(imageData: Data, previousResponseId: String?) async -> StreamResult {
        await service.streamFeedback(imageData: imageData, previousResponseId: previousResponseId)
    }

    func streamFollowup(question: String, previousResponseId: String) async -> StreamResult {
        await service.streamFollowup(question: question, previousResponseId: previousResponseId)
    }

    func clearSession() async {
        await service.clearSession()
    }
}