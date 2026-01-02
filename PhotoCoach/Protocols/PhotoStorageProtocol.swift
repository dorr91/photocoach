import UIKit

protocol PhotoStorageProtocol {
    func savePhoto(_ image: UIImage, id: UUID) -> (imagePath: String, thumbnailPath: String)?
    func loadImage(path: String) -> UIImage?
    func loadThumbnail(path: String) -> UIImage?
    func deletePhoto(imagePath: String, thumbnailPath: String)
    func imageDataForAPI(path: String, maxDimension: CGFloat) -> Data?
}