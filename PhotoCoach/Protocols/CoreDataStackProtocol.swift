import CoreData
import SwiftUI

protocol CoreDataStackProtocol: AnyObject {
    var viewContext: NSManagedObjectContext { get }
    
    func save()
    
    // Photo Operations
    func createPhoto(imagePath: String, thumbnailPath: String) -> Photo
    func fetchPhotos() -> [Photo]
    func deletePhoto(_ photo: Photo)
    
    // Feedback Operations
    func createFeedback(for photo: Photo) -> AIFeedback
    func updateFeedback(_ feedback: AIFeedback, content: String, isComplete: Bool)
    func fetchFeedback(for photo: Photo) -> AIFeedback?
}