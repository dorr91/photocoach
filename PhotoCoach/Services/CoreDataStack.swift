import CoreData
import SwiftUI

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PhotoCoach")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
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

    func createPhoto(imagePath: String, thumbnailPath: String) -> Photo {
        let photo = Photo(context: viewContext)
        photo.id = UUID()
        photo.capturedAt = Date()
        photo.imagePath = imagePath
        photo.thumbnailPath = thumbnailPath
        save()
        return photo
    }

    func fetchPhotos() -> [Photo] {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Photo.capturedAt, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching photos: \(error)")
            return []
        }
    }

    func deletePhoto(_ photo: Photo) {
        if let imagePath = photo.imagePath, let thumbnailPath = photo.thumbnailPath {
            PhotoStorage.deletePhoto(imagePath: imagePath, thumbnailPath: thumbnailPath)
        }
        viewContext.delete(photo)
        save()
    }

    // MARK: - Feedback Operations

    func createFeedback(for photo: Photo) -> AIFeedback {
        let feedback = AIFeedback(context: viewContext)
        feedback.id = UUID()
        feedback.photoId = photo.id
        feedback.content = ""
        feedback.isComplete = false
        feedback.createdAt = Date()
        save()
        return feedback
    }

    func updateFeedback(_ feedback: AIFeedback, content: String, isComplete: Bool) {
        feedback.content = content
        feedback.isComplete = isComplete
        save()
    }

    func fetchFeedback(for photo: Photo) -> AIFeedback? {
        let request: NSFetchRequest<AIFeedback> = AIFeedback.fetchRequest()
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
