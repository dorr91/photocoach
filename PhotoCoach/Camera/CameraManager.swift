import AVFoundation
import UIKit

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var capturedImage: UIImage?
    @Published var permissionGranted = false
    @Published var permissionDenied = false
    @Published var isCapturing = false

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?

    override init() {
        super.init()
    }

    func checkPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            await setupSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permissionGranted = granted
            permissionDenied = !granted
            if granted {
                await setupSession()
            }
        case .denied, .restricted:
            permissionDenied = true
        @unknown default:
            permissionDenied = true
        }
    }

    private func setupSession() async {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Add back camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        }

        session.commitConfiguration()

        // Start session on background thread
        let captureSession = session
        Task.detached {
            captureSession.startRunning()
        }

        // Small delay to let session start, then update state
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            isSessionRunning = true
        }
    }

    func capturePhoto() async -> UIImage? {
        guard isSessionRunning, !isCapturing else { return nil }

        isCapturing = true

        let settings = AVCapturePhotoSettings()
        settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions

        return await withCheckedContinuation { continuation in
            self.photoContinuation = continuation
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func stopSession() {
        let captureSession = session
        Task.detached {
            captureSession.stopRunning()
        }
        isSessionRunning = false
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        Task { @MainActor in
            defer {
                isCapturing = false
            }

            guard error == nil,
                  let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else {
                photoContinuation?.resume(returning: nil)
                photoContinuation = nil
                return
            }

            // Fix orientation
            let fixedImage = fixOrientation(image)
            capturedImage = fixedImage
            photoContinuation?.resume(returning: fixedImage)
            photoContinuation = nil
        }
    }

    @MainActor
    private func fixOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? image
    }
}
