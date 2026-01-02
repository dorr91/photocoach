import SwiftUI

struct PhotoCard: View {
    let photo: Photo
    let container: ServiceContainer
    let showSummaryOnly: Bool
    @StateObject private var feedbackVM: FeedbackViewModel
    @State private var image: UIImage?

    init(photo: Photo, container: ServiceContainer, showSummaryOnly: Bool = false) {
        self.photo = photo
        self.container = container
        self.showSummaryOnly = showSummaryOnly
        self._feedbackVM = StateObject(wrappedValue: FeedbackViewModel(
            coreData: container.coreDataStack,
            openAIService: container.openAIService,
            photoStorage: container.photoStorage
        ))
    }

    private var summaryText: String {
        let text = feedbackVM.displayText
        guard showSummaryOnly, text.count > 150 else { return text }

        let truncated = String(text.prefix(150))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        return truncated + "..."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Photo
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(4/3, contentMode: .fit)
                    .overlay {
                        ProgressView()
                    }
            }

            // Timestamp
            if let capturedAt = photo.capturedAt {
                Text(capturedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                + Text(" at ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                + Text(capturedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Feedback section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("AI Feedback")
                        .font(.headline)

                    Spacer()

                    if feedbackVM.isLoading || feedbackVM.isStreaming {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if showSummaryOnly {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }

                if feedbackVM.hasError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(feedbackVM.displayText)
                            .foregroundStyle(.red)
                            .font(.subheadline)

                        if !showSummaryOnly {
                            Button {
                                Task {
                                    await feedbackVM.retry(for: photo)
                                }
                            } label: {
                                Label("Retry", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else if feedbackVM.displayText.isEmpty && feedbackVM.isLoading {
                    Text("Analyzing your photo...")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else if showSummaryOnly {
                    Text(summaryText)
                        .font(.subheadline)
                } else {
                    Text(summaryText)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.systemBackground))
        .task {
            await loadImage()
            feedbackVM.loadExistingFeedback(for: photo)

            // Auto-fetch if not complete
            if !feedbackVM.isComplete {
                await feedbackVM.fetchFeedback(for: photo)
            }
        }
    }

    private func loadImage() async {
        // Use thumbnail in summary mode for faster loading
        let useThumbnail = showSummaryOnly
        let path = useThumbnail ? photo.thumbnailPath : photo.imagePath
        guard let imagePath = path else { return }

        // Capture photoStorage before detaching to avoid actor isolation issues
        let photoStorage = container.photoStorage

        // Load image off main thread
        let loadedImage = await Task.detached(priority: .userInitiated) {
            useThumbnail
                ? photoStorage.loadThumbnail(path: imagePath)
                : photoStorage.loadImage(path: imagePath)
        }.value

        image = loadedImage
    }
}

#Preview {
    let container = ServiceContainer(inMemory: true)
    let coreData = container.coreDataStack as! CoreDataStack
    let photo = Photo(context: coreData.viewContext)
    photo.id = UUID()
    photo.capturedAt = Date()
    photo.imagePath = "preview"
    photo.thumbnailPath = "preview"

    return ScrollView {
        PhotoCard(photo: photo, container: container)
    }
}
