import Foundation
import SwiftUI

enum FeedbackState {
    case idle
    case loading
    case streaming(String)
    case complete(String)
    case error(String)
}

@MainActor
class FeedbackViewModel: ObservableObject {
    @Published var state: FeedbackState = .idle

    private let coreData: CoreDataStack

    init(coreData: CoreDataStack) {
        self.coreData = coreData
    }

    var displayText: String {
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

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var isStreaming: Bool {
        if case .streaming = state { return true }
        return false
    }

    var hasError: Bool {
        if case .error = state { return true }
        return false
    }

    var isComplete: Bool {
        if case .complete = state { return true }
        return false
    }

    func loadExistingFeedback(for photo: Photo) {
        if let feedback = coreData.fetchFeedback(for: photo),
           feedback.isComplete,
           let content = feedback.content, !content.isEmpty {
            state = .complete(content)
        }
    }

    func fetchFeedback(for photo: Photo) async {
        // Check if we already have complete feedback
        if let feedback = coreData.fetchFeedback(for: photo),
           feedback.isComplete,
           let content = feedback.content, !content.isEmpty {
            state = .complete(content)
            return
        }

        guard let imagePath = photo.imagePath,
              let imageData = PhotoStorage.imageDataForAPI(path: imagePath) else {
            state = .error("Could not load photo.")
            return
        }

        state = .loading
        var accumulatedText = ""

        do {
            let stream = await OpenAIService.shared.streamFeedback(imageData: imageData)

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

    func retry(for photo: Photo) async {
        state = .idle
        await fetchFeedback(for: photo)
    }
}
