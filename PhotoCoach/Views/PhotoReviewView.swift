import SwiftUI

struct PhotoReviewView: View {
    @EnvironmentObject var container: ServiceContainer
    @EnvironmentObject var coreData: CoreDataStack
    @State private var photos: [Photo] = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if photos.isEmpty {
                    emptyState
                } else {
                    ForEach(photos, id: \.id) { photo in
                        PhotoCard(photo: photo, container: container)
                        Divider()
                    }
                }
            }
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshPhotos()
        }
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

    private func refreshPhotos() {
        photos = coreData.fetchPhotos()
    }
}

#Preview {
    NavigationStack {
        PhotoReviewView()
    }
    .environmentObject(CoreDataStack(inMemory: true, photoStorage: PhotoStorageService()))
}
