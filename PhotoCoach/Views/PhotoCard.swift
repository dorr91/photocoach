import SwiftUI

struct PhotoCard: View {
    let photo: Photo
    @StateObject private var feedbackVM: FeedbackViewModel
    @State private var image: UIImage?

    init(photo: Photo, coreData: CoreDataStack) {
        self.photo = photo
        self._feedbackVM = StateObject(wrappedValue: FeedbackViewModel(coreData: coreData))
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
            loadImage()
            feedbackVM.loadExistingFeedback(for: photo)

            // Auto-fetch if not complete
            if !feedbackVM.isComplete {
                await feedbackVM.fetchFeedback(for: photo)
            }
        }
    }

    private func loadImage() {
        if let imagePath = photo.imagePath {
            image = PhotoStorage.loadImage(path: imagePath)
        }
    }
}

#Preview {
    let coreData = CoreDataStack(inMemory: true)
    let photo = Photo(context: coreData.viewContext)
    photo.id = UUID()
    photo.capturedAt = Date()
    photo.imagePath = "preview"
    photo.thumbnailPath = "preview"

    return ScrollView {
        PhotoCard(photo: photo, coreData: coreData)
    }
}
