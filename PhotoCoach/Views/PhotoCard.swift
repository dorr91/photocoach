import SwiftUI

struct PhotoCard: View {
    let photo: Photo
    let container: ServiceContainer
    @StateObject private var feedbackVM: FeedbackViewModel
    @State private var image: UIImage?

    init(photo: Photo, container: ServiceContainer) {
        self.photo = photo
        self.container = container
        self._feedbackVM = StateObject(wrappedValue: FeedbackViewModel(
            coreData: container.coreDataStack,
            openAIService: container.openAIService,
            photoStorage: container.photoStorage
        ))
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
                    }
                }

                if feedbackVM.hasError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(feedbackVM.displayText)
                            .foregroundStyle(.red)
                            .font(.subheadline)

                        Button {
                            Task {
                                await feedbackVM.retry(for: photo)
                            }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                } else if feedbackVM.displayText.isEmpty && feedbackVM.isLoading {
                    Text("Analyzing your photo...")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    Text(feedbackVM.displayText)
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
        guard let imagePath = photo.imagePath else { return }

        // Load image off main thread
        let loadedImage = await Task.detached(priority: .userInitiated) {
            self.container.photoStorage.loadImage(path: imagePath)
        }.value

        await MainActor.run {
            self.image = loadedImage
        }
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
