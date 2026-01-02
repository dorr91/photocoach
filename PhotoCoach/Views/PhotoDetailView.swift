import SwiftUI

struct PhotoDetailView: View {
    let photo: Photo
    let container: ServiceContainer
    @Binding var showGallery: Bool

    @StateObject private var feedbackVM: FeedbackViewModel
    @State private var image: UIImage?
    @State private var followupText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    init(photo: Photo, container: ServiceContainer, showGallery: Binding<Bool>) {
        self.photo = photo
        self.container = container
        self._showGallery = showGallery
        self._feedbackVM = StateObject(wrappedValue: FeedbackViewModel(
            coreData: container.coreDataStack,
            openAIService: container.openAIService,
            photoStorage: container.photoStorage
        ))
    }

    private var canSendFollowup: Bool {
        !followupText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !feedbackVM.isLoading
            && !feedbackVM.isStreaming
            && feedbackVM.isComplete
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Photo
                    photoSection

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
                    feedbackSection

                    // Followup input section
                    followupSection
                        .id("followupSection")
                }
                .padding()
            }
            .onChange(of: feedbackVM.displayText) {
                // Auto-scroll to bottom when new content streams in
                withAnimation {
                    proxy.scrollTo("followupSection", anchor: .bottom)
                }
            }
        }
        .navigationTitle("Photo Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showGallery = true
                } label: {
                    Label("Gallery", systemImage: "square.grid.2x2")
                }
            }
        }
        .task {
            await loadImage()
            feedbackVM.loadExistingFeedback(for: photo)

            // Auto-fetch if not complete
            if !feedbackVM.isComplete {
                await feedbackVM.fetchFeedback(for: photo)
            }
        }
    }

    @ViewBuilder
    private var photoSection: some View {
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
    }

    @ViewBuilder
    private var feedbackSection: some View {
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

    @ViewBuilder
    private var followupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask a followup question")
                .font(.headline)

            HStack(spacing: 8) {
                TextField("e.g., How could I improve the composition?", text: $followupText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .focused($isTextFieldFocused)
                    .disabled(feedbackVM.isLoading || feedbackVM.isStreaming)
                    .onSubmit {
                        if canSendFollowup {
                            sendFollowup()
                        }
                    }

                Button {
                    sendFollowup()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(!canSendFollowup)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadImage() async {
        guard let imagePath = photo.imagePath else { return }

        let photoStorage = container.photoStorage

        let loadedImage = await Task.detached(priority: .userInitiated) {
            photoStorage.loadImage(path: imagePath)
        }.value

        image = loadedImage
    }

    private func sendFollowup() {
        let question = followupText
        followupText = ""
        isTextFieldFocused = false

        Task {
            await feedbackVM.sendFollowup(question: question, for: photo)
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

    return NavigationStack {
        PhotoDetailView(photo: photo, container: container, showGallery: .constant(false))
    }
}
