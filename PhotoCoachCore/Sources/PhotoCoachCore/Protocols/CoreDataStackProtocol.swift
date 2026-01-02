import CoreData
import Foundation

public protocol CoreDataStackProtocol: AnyObject {
    var viewContext: NSManagedObjectContext { get }
    func save()
    
    // Photo operations
    func createPhoto(imagePath: String, thumbnailPath: String) -> Photo
    func fetchPhotos() -> [Photo]
    func deletePhoto(_ photo: Photo)
    
    // Feedback operations
    func createFeedback(for photo: Photo) -> AIFeedback
    func updateFeedback(_ feedback: AIFeedback, content: String, isComplete: Bool)
    func fetchFeedback(for photo: Photo) -> AIFeedback?
}