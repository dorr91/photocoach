import Foundation

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformFloat = CGFloat
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformFloat = CGFloat
#else
// For testing without UIKit/AppKit
public typealias PlatformFloat = Double
public class PlatformImage {
    public init() {}
}
#endif

public protocol PhotoStorageProtocol {
    func savePhoto(_ image: PlatformImage, id: UUID) -> (imagePath: String, thumbnailPath: String)?
    func loadImage(path: String) -> PlatformImage?
    func loadThumbnail(path: String) -> PlatformImage?
    func deletePhoto(imagePath: String, thumbnailPath: String)
    func imageDataForAPI(path: String, maxDimension: PlatformFloat) -> Data?
}