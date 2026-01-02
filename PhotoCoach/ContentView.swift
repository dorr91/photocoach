import SwiftUI

struct ContentView: View {
    @EnvironmentObject var container: ServiceContainer
    @EnvironmentObject var coreData: CoreDataStack
    @State private var selectedPhotoId: UUID?
    @State private var showGallery = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            CameraView(selectedPhotoId: $selectedPhotoId, showGallery: $showGallery, showSettings: $showSettings)
                .navigationDestination(item: $selectedPhotoId) { photoId in
                    if let photo = coreData.fetchPhoto(by: photoId) {
                        PhotoDetailView(photo: photo, container: container, showGallery: $showGallery)
                    }
                }
                .navigationDestination(isPresented: $showGallery) {
                    PhotoReviewView(onSelectPhoto: { photo in
                        // Dismiss gallery first, then navigate to detail
                        showGallery = false
                        // Use slight delay to let dismiss animation complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectedPhotoId = photo.id
                        }
                    })
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
        }
    }
}

#Preview {
    let container = ServiceContainer(inMemory: true)
    return ContentView()
        .environmentObject(container)
        .environmentObject(container.coreDataStack as! CoreDataStack)
}
