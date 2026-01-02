import UIKit

class PhotoStorageService: PhotoStorageProtocol {
    private let fileManager: FileManagerProtocol
    
    init(fileManager: FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }
    private var photosDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosDir = documentsDirectory.appendingPathComponent("Photos", isDirectory: true)

        if !fileManager.fileExists(atPath: photosDir.path) {
            try? fileManager.createDirectory(at: photosDir, withIntermediateDirectories: true, attributes: nil)
        }

        return photosDir
    }

    private var thumbnailsDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbsDir = documentsDirectory.appendingPathComponent("Thumbnails", isDirectory: true)

        if !fileManager.fileExists(atPath: thumbsDir.path) {
            try? fileManager.createDirectory(at: thumbsDir, withIntermediateDirectories: true, attributes: nil)
        }

        return thumbsDir
    }

    func savePhoto(_ image: UIImage, id: UUID) -> (imagePath: String, thumbnailPath: String)? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }

        let imagePath = "\(id.uuidString).jpg"
        let thumbnailPath = "\(id.uuidString)_thumb.jpg"

        let imageURL = photosDirectory.appendingPathComponent(imagePath)
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(thumbnailPath)

        do {
            try imageData.write(to: imageURL)

            // Generate thumbnail
            if let thumbnail = generateThumbnail(from: image, maxSize: 200),
               let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
                try thumbnailData.write(to: thumbnailURL)
            }

            return (imagePath, thumbnailPath)
        } catch {
            print("Error saving photo: \(error)")
            return nil
        }
    }

    func loadImage(path: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func loadThumbnail(path: String) -> UIImage? {
        let url = thumbnailsDirectory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deletePhoto(imagePath: String, thumbnailPath: String) {
        let imageURL = photosDirectory.appendingPathComponent(imagePath)
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(thumbnailPath)

        try? fileManager.removeItem(at: imageURL)
        try? fileManager.removeItem(at: thumbnailURL)
    }

    private func generateThumbnail(from image: UIImage, maxSize: CGFloat) -> UIImage? {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func imageDataForAPI(path: String, maxDimension: CGFloat = 1024) -> Data? {
        guard let image = loadImage(path: path) else { return nil }

        // Resize if needed for API
        let size = image.size
        if size.width <= maxDimension && size.height <= maxDimension {
            return image.jpegData(compressionQuality: 0.8)
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: 0.8)
    }
}
