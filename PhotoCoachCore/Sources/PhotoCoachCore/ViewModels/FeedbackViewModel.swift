import Foundation
import SwiftUI

public enum FeedbackState: Equatable {
    case idle
    case loading
    case streaming(String)
    case complete(String)
    case error(String)
}

@MainActor
public class FeedbackViewModel: ObservableObject {
    @Published public var state: FeedbackState = .idle

    private let coreData: CoreDataStackProtocol
    private let openAIService: OpenAIServiceType
    private let photoStorage: PhotoStorageProtocol

    public init(coreData: CoreDataStackProtocol, openAIService: OpenAIServiceType, photoStorage: PhotoStorageProtocol) {
        self.coreData = coreData
        self.openAIService = openAIService
        self.photoStorage = photoStorage
    }

    public var displayText: String {
        switch state {
        case .idle:
            return ""
        case .loading:
            return ""
        case .streaming(let text), .complete(let text):
            return text
        case .error(let message):
            return message
        }
    }

    public var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    public var isStreaming: Bool {
        if case .streaming = state { return true }
        return false
    }

    public var hasError: Bool {
        if case .error = state { return true }
        return false
    }

    public var isComplete: Bool {
        if case .complete = state { return true }
        return false
    }

    public func loadExistingFeedback(for photo: Photo) {
        if let feedback = coreData.fetchFeedback(for: photo),
           feedback.isComplete,
           let content = feedback.content, !content.isEmpty {
            state = .complete(content)
        }
    }

    public func fetchFeedback(for photo: Photo) async {
        // Check if we already have complete feedback
        if let feedback = coreData.fetchFeedback(for: photo),
           feedback.isComplete,
           let content = feedback.content, !content.isEmpty {
            state = .complete(content)
            return
        }

        guard let imagePath = photo.imagePath,
              let imageData = photoStorage.imageDataForAPI(path: imagePath, maxDimension: 1024) else {
            state = .error("Could not load photo.")
            return
        }

        state = .loading
        var accumulatedText = ""

        do {
            let stream = await openAIService.streamFeedback(imageData: imageData)

            for try await chunk in stream {
                accumulatedText += chunk
                state = .streaming(accumulatedText)
            }

            state = .complete(accumulatedText)

            // Save to Core Data
            if let feedback = coreData.fetchFeedback(for: photo) {
                coreData.updateFeedback(feedback, content: accumulatedText, isComplete: true)
            }
        } catch {
            let errorMessage = (error as? OpenAIError)?.errorDescription ?? error.localizedDescription
            state = .error(errorMessage)
        }
    }

    public func retry(for photo: Photo) async {
        state = .idle
        await fetchFeedback(for: photo)
    }
    
    // Test-friendly aliases
    public func analyzePhoto(_ photo: Photo) async {
        await fetchFeedback(for: photo)
    }
    
    public func resetState() {
        state = .idle
    }
}
