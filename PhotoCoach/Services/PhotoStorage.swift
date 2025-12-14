import UIKit

enum PhotoStorage {
    private static var photosDirectory: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosDir = documentsDirectory.appendingPathComponent("Photos", isDirectory: true)

        if !FileManager.default.fileExists(atPath: photosDir.path) {
            try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
        }

        return photosDir
    }

    private static var thumbnailsDirectory: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbsDir = documentsDirectory.appendingPathComponent("Thumbnails", isDirectory: true)

        if !FileManager.default.fileExists(atPath: thumbsDir.path) {
            try? FileManager.default.createDirectory(at: thumbsDir, withIntermediateDirectories: true)
        }

        return thumbsDir
    }

    static func savePhoto(_ image: UIImage, id: UUID) -> (imagePath: String, thumbnailPath: String)? {
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

    static func loadImage(path: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func loadThumbnail(path: String) -> UIImage? {
        let url = thumbnailsDirectory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func deletePhoto(imagePath: String, thumbnailPath: String) {
        let imageURL = photosDirectory.appendingPathComponent(imagePath)
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(thumbnailPath)

        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: thumbnailURL)
    }

    private static func generateThumbnail(from image: UIImage, maxSize: CGFloat) -> UIImage? {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    static func imageDataForAPI(path: String, maxDimension: CGFloat = 1024) -> Data? {
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
