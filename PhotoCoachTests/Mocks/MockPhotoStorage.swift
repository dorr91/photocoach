import Foundation
@testable import PhotoCoach

// For unit tests, we need minimal UIKit substitutes for macOS
#if canImport(UIKit)
import UIKit
#else
// Simple mock types for macOS unit testing
struct CGSize {
    let width: Double
    let height: Double
    init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

typealias CGFloat = Double

class UIImage {
    let size: CGSize
    init() { self.size = CGSize(width: 100, height: 100) }
}
#endif

class MockPhotoStorage: PhotoStorageProtocol {
    private var storage: [String: UIImage] = [:]
    private var thumbnails: [String: UIImage] = [:]
    
    var savePhotoCallCount = 0
    var loadImageCallCount = 0
    var loadThumbnailCallCount = 0
    var deletePhotoCallCount = 0
    var imageDataForAPICallCount = 0
    
    var shouldFailSave = false
    var shouldFailLoad = false
    
    func savePhoto(_ image: UIImage, id: UUID) -> (imagePath: String, thumbnailPath: String)? {
        savePhotoCallCount += 1
        
        if shouldFailSave {
            return nil
        }
        
        let imagePath = "image_\(id.uuidString).jpg"
        let thumbnailPath = "thumb_\(id.uuidString).jpg"
        
        storage[imagePath] = image
        
        // Create a simple thumbnail (just store the same image for testing)
        thumbnails[thumbnailPath] = image
        
        return (imagePath, thumbnailPath)
    }
    
    func loadImage(path: String) -> UIImage? {
        loadImageCallCount += 1
        
        if shouldFailLoad {
            return nil
        }
        
        return storage[path]
    }
    
    func loadThumbnail(path: String) -> UIImage? {
        loadThumbnailCallCount += 1
        
        if shouldFailLoad {
            return nil
        }
        
        return thumbnails[path]
    }
    
    func deletePhoto(imagePath: String, thumbnailPath: String) {
        deletePhotoCallCount += 1
        storage.removeValue(forKey: imagePath)
        thumbnails.removeValue(forKey: thumbnailPath)
    }
    
    func imageDataForAPI(path: String, maxDimension: CGFloat) -> Data? {
        imageDataForAPICallCount += 1
        
        guard let image = storage[path] else {
            return nil
        }
        
        // Return simple JPEG data for testing
        return image.jpegData(compressionQuality: 0.8)
    }
    
    // Test helper methods
    func reset() {
        storage.removeAll()
        thumbnails.removeAll()
        savePhotoCallCount = 0
        loadImageCallCount = 0
        loadThumbnailCallCount = 0
        deletePhotoCallCount = 0
        imageDataForAPICallCount = 0
        shouldFailSave = false
        shouldFailLoad = false
    }
    
    func hasImage(at path: String) -> Bool {
        return storage[path] != nil
    }
    
    func hasThumbnail(at path: String) -> Bool {
        return thumbnails[path] != nil
    }
    
    var storedImageCount: Int {
        return storage.count
    }
}