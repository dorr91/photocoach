import CoreData
import SwiftUI

public class CoreDataStack: ObservableObject, CoreDataStackProtocol {
    let container: NSPersistentContainer
    private let photoStorage: PhotoStorageProtocol

    public init(inMemory: Bool = false, photoStorage: PhotoStorageProtocol) {
        self.photoStorage = photoStorage
        
        // Try to load model from Swift Package bundle, fall back to programmatic creation
        let bundle = Bundle.module
        var managedObjectModel: NSManagedObjectModel?
        
        if let modelURL = bundle.url(forResource: "PhotoCoach", withExtension: "momd") {
            managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
        } else if let modelURL = bundle.url(forResource: "PhotoCoach", withExtension: "xcdatamodeld") {
            managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
        }
        
        // Create container with explicit model
        if let model = managedObjectModel {
            container = NSPersistentContainer(name: "PhotoCoach", managedObjectModel: model)
        } else {
            // Fallback to default model loading
            container = NSPersistentContainer(name: "PhotoCoach")
        }

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("CoreData error (using fallback): \(error)")
                // Don't fatal error in package context
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    public func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }

    // MARK: - Photo Operations

    public func createPhoto(imagePath: String, thumbnailPath: String) -> Photo {
        let photo = Photo(context: viewContext)
        photo.id = UUID()
        photo.capturedAt = Date()
        photo.imagePath = imagePath
        photo.thumbnailPath = thumbnailPath
        save()
        return photo
    }

    public func fetchPhotos() -> [Photo] {
        let request = NSFetchRequest<Photo>(entityName: "Photo")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Photo.capturedAt, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching photos: \(error)")
            return []
        }
    }

    public func deletePhoto(_ photo: Photo) {
        if let imagePath = photo.imagePath, let thumbnailPath = photo.thumbnailPath {
            photoStorage.deletePhoto(imagePath: imagePath, thumbnailPath: thumbnailPath)
        }
        viewContext.delete(photo)
        save()
    }

    // MARK: - Feedback Operations

    public func createFeedback(for photo: Photo) -> AIFeedback {
        let feedback = AIFeedback(context: viewContext)
        feedback.id = UUID()
        feedback.photoId = photo.id
        feedback.content = ""
        feedback.isComplete = false
        feedback.createdAt = Date()
        save()
        return feedback
    }

    public func updateFeedback(_ feedback: AIFeedback, content: String, isComplete: Bool) {
        feedback.content = content
        feedback.isComplete = isComplete
        save()
    }

    public func fetchFeedback(for photo: Photo) -> AIFeedback? {
        let request = NSFetchRequest<AIFeedback>(entityName: "AIFeedback")
        request.predicate = NSPredicate(format: "photoId == %@", photo.id! as CVarArg)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error fetching feedback: \(error)")
            return nil
        }
    }
}
