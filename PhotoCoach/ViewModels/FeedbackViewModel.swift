import Foundation
import SwiftUI

enum FeedbackState: Equatable {
    case idle
    case loading
    case streaming(String)
    case complete(String)
    case error(String)
}

@MainActor
class FeedbackViewModel: ObservableObject {
    @Published var state: FeedbackState = .idle

    private let coreData: CoreDataStackProtocol
    private let openAIService: OpenAIServiceType
    private let photoStorage: PhotoStorageProtocol

    // Store the current photo's responseId for followups
    private var currentResponseId: String?

    init(coreData: CoreDataStackProtocol, openAIService: OpenAIServiceType, photoStorage: PhotoStorageProtocol) {
        self.coreData = coreData
        self.openAIService = openAIService
        self.photoStorage = photoStorage
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

    var canAskFollowup: Bool {
        currentResponseId != nil && isComplete
    }

    func loadExistingFeedback(for photo: Photo) {
        if let feedback = coreData.fetchFeedback(for: photo),
           feedback.isComplete,
           let content = feedback.content, !content.isEmpty {
            state = .complete(content)
            // Load the stored responseId for followups
            currentResponseId = feedback.responseId
        }
    }

    func fetchFeedback(for photo: Photo) async {
        // Check if we already have complete feedback
        if let feedback = coreData.fetchFeedback(for: photo),
           feedback.isComplete,
           let content = feedback.content, !content.isEmpty {
            state = .complete(content)
            currentResponseId = feedback.responseId
            return
        }

        guard let imagePath = photo.imagePath else {
            state = .error("Could not load photo.")
            return
        }

        state = .loading

        // Capture photoStorage before detaching to avoid actor isolation issues
        let storage = photoStorage

        // Load and resize image off main thread
        let imageData = await Task.detached(priority: .userInitiated) {
            storage.imageDataForAPI(path: imagePath, maxDimension: 1024)
        }.value

        guard let imageData else {
            state = .error("Could not load photo.")
            return
        }

        var accumulatedText = ""
        var lastUpdateTime = Date()
        let updateInterval: TimeInterval = 0.1

        do {
            // Pass nil for previousResponseId since this is initial feedback for this photo
            let result = await openAIService.streamFeedback(imageData: imageData, previousResponseId: nil)

            for try await chunk in result.stream {
                accumulatedText += chunk

                let now = Date()
                if now.timeIntervalSince(lastUpdateTime) >= updateInterval {
                    state = .streaming(accumulatedText)
                    lastUpdateTime = now
                }
            }

            state = .complete(accumulatedText)

            // Get the responseId for future followups
            let responseId = await result.responseId()
            currentResponseId = responseId

            // Save to Core Data with responseId
            if let feedback = coreData.fetchFeedback(for: photo) {
                coreData.updateFeedback(feedback, content: accumulatedText, isComplete: true, responseId: responseId)
            }
        } catch {
            let errorMessage = (error as? OpenAIError)?.errorDescription ?? error.localizedDescription
            state = .error(errorMessage)
        }
    }

    func retry(for photo: Photo) async {
        state = .idle
        currentResponseId = nil
        await fetchFeedback(for: photo)
    }

    func sendFollowup(question: String, for photo: Photo) async {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else { return }

        guard let previousResponseId = currentResponseId else {
            state = .error("Cannot ask followup questions. Please wait for the initial analysis to complete.")
            return
        }

        let currentText = displayText
        let questionPrefix = "\n\n---\n\n**Your question:** \(trimmedQuestion)\n\n**Response:** "

        state = .streaming(currentText + questionPrefix)

        var accumulatedFollowupText = ""
        var lastUpdateTime = Date()
        let updateInterval: TimeInterval = 0.1

        do {
            let result = await openAIService.streamFollowup(question: trimmedQuestion, previousResponseId: previousResponseId)

            for try await chunk in result.stream {
                accumulatedFollowupText += chunk

                let now = Date()
                if now.timeIntervalSince(lastUpdateTime) >= updateInterval {
                    state = .streaming(currentText + questionPrefix + accumulatedFollowupText)
                    lastUpdateTime = now
                }
            }

            let finalText = currentText + questionPrefix + accumulatedFollowupText
            state = .complete(finalText)

            // Update responseId for next followup
            let newResponseId = await result.responseId()
            if let newResponseId = newResponseId {
                currentResponseId = newResponseId
            }

            // Update stored feedback with new content and responseId
            if let feedback = coreData.fetchFeedback(for: photo) {
                coreData.updateFeedback(feedback, content: finalText, isComplete: true, responseId: currentResponseId)
            }
        } catch {
            let errorMessage = (error as? OpenAIError)?.errorDescription ?? error.localizedDescription
            state = .error(errorMessage)
        }
    }

    // Test-friendly aliases
    func analyzePhoto(_ photo: Photo) async {
        await fetchFeedback(for: photo)
    }

    func resetState() {
        state = .idle
        currentResponseId = nil
    }
}
