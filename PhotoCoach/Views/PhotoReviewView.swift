import SwiftUI

struct PhotoReviewView: View {
    @EnvironmentObject var container: ServiceContainer
    @EnvironmentObject var coreData: CoreDataStack
    @State private var photos: [Photo] = []

    var body: some View {
        Group {
            if photos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(photos, id: \.id) { photo in
                            PhotoCard(photo: photo, container: container)
                            Divider()
                        }
                    }
                }
            }
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPhotos()
        }
    }

    private func loadPhotos() async {
        // Yield to allow navigation animation to complete first
        await Task.yield()
        photos = coreData.fetchPhotos()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Photos Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Take a photo to get AI coaching feedback")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

}

#Preview {
    NavigationStack {
        PhotoReviewView()
    }
    .environmentObject(CoreDataStack(inMemory: true, photoStorage: PhotoStorageService()))
}
