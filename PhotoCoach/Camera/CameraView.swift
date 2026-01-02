import SwiftUI
import PhotosUI

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @EnvironmentObject var container: ServiceContainer
    @EnvironmentObject var coreData: CoreDataStack
    @Binding var selectedPhotoId: UUID?
    @Binding var showGallery: Bool
    @Binding var showSettings: Bool

    @State private var lastThumbnail: UIImage?
    @State private var showCaptureFlash = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @AppStorage("showGrid") private var showGrid = false

    var body: some View {
        ZStack {
            // Camera preview
            if cameraManager.permissionGranted {
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()
            } else if cameraManager.permissionDenied {
                permissionDeniedView
            } else {
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            }

            // Grid overlay
            if showGrid && cameraManager.permissionGranted {
                GridOverlay()
                    .ignoresSafeArea()
            }
            
            // Capture flash overlay
            if showCaptureFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Controls overlay
            VStack {
                // Top bar with settings
                HStack {
                    Spacer()
                    
                    Button {
                        showGrid.toggle()
                    } label: {
                        Image(systemName: "grid")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(showGrid ? Color.blue : Color.clear, in: Circle())
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding()

                Spacer()

                // Bottom controls
                HStack(alignment: .center) {
                    // Thumbnail to gallery
                    Button {
                        showGallery = true
                    } label: {
                        if let thumbnail = lastThumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.white, lineWidth: 2)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundStyle(.white.opacity(0.5))
                                )
                        }
                    }

                    Spacer()

                    // Shutter button
                    Button {
                        Task {
                            await capturePhoto()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 4)
                                .frame(width: 72, height: 72)
                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                        }
                    }
                    .disabled(cameraManager.isCapturing || !cameraManager.isSessionRunning)
                    .opacity(cameraManager.isCapturing ? 0.5 : 1)

                    Spacer()

                    // Photo library picker
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await handleSelectedPhoto(newItem)
            }
        }
        .task {
            await cameraManager.checkPermission()
            loadLastThumbnail()
        }
        .onAppear {
            AppDelegate.orientationLock = .portrait
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
        .onDisappear {
            AppDelegate.orientationLock = .allButUpsideDown
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("PhotoCoach needs camera access to capture photos for AI coaching.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func capturePhoto() async {
        // Flash animation
        withAnimation(.easeInOut(duration: 0.1)) {
            showCaptureFlash = true
        }

        if let image = await cameraManager.capturePhoto() {
            savePhotoAndNavigate(image)
        }

        withAnimation(.easeInOut(duration: 0.1)) {
            showCaptureFlash = false
        }
    }

    private func handleSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            savePhotoAndNavigate(image)
        }

        // Clear selection so user can pick the same photo again
        selectedPhotoItem = nil
    }

    private func savePhotoAndNavigate(_ image: UIImage) {
        if let paths = container.photoStorage.savePhoto(image, id: UUID()) {
            let photo = coreData.createPhoto(imagePath: paths.imagePath, thumbnailPath: paths.thumbnailPath)
            _ = coreData.createFeedback(for: photo)

            // Update thumbnail
            lastThumbnail = container.photoStorage.loadThumbnail(path: paths.thumbnailPath)

            // Navigate to detail view for this photo
            selectedPhotoId = photo.id
        }
    }

    private func loadLastThumbnail() {
        let photos = coreData.fetchPhotos()
        if let lastPhoto = photos.first, let thumbPath = lastPhoto.thumbnailPath {
            lastThumbnail = container.photoStorage.loadThumbnail(path: thumbPath)
        }
    }
}

#Preview {
    CameraView(selectedPhotoId: .constant(nil), showGallery: .constant(false), showSettings: .constant(false))
        .environmentObject(CoreDataStack(inMemory: true, photoStorage: PhotoStorageService()))
}
