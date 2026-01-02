import CoreData
@testable import PhotoCoach

class MockCoreDataStack: CoreDataStackProtocol {
    private let inMemoryContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        inMemoryContainer.viewContext
    }
    
    var saveCallCount = 0
    var createPhotoCallCount = 0
    var fetchPhotosCallCount = 0
    var fetchPhotoByIdCallCount = 0
    var deletePhotoCallCount = 0
    var createFeedbackCallCount = 0
    var updateFeedbackCallCount = 0
    var fetchFeedbackCallCount = 0
    
    var shouldFailSave = false
    var saveError: Error?
    
    init() {
        self.inMemoryContainer = NSPersistentContainer(name: "PhotoCoach")
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        inMemoryContainer.persistentStoreDescriptions = [description]
        
        inMemoryContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        
        inMemoryContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        saveCallCount += 1
        
        if shouldFailSave {
            if let error = saveError {
                print("Mock save error: \(error)")
            }
            return
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Mock save failed: \(error)")
        }
    }
    
    func createPhoto(imagePath: String, thumbnailPath: String) -> Photo {
        createPhotoCallCount += 1
        
        let photo = Photo(context: viewContext)
        photo.id = UUID()
        photo.imagePath = imagePath
        photo.thumbnailPath = thumbnailPath
        photo.capturedAt = Date()
        
        return photo
    }
    
    func fetchPhotos() -> [Photo] {
        fetchPhotosCallCount += 1

        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Photo.capturedAt, ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch photos: \(error)")
            return []
        }
    }

    func fetchPhoto(by id: UUID) -> Photo? {
        fetchPhotoByIdCallCount += 1

        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Failed to fetch photo: \(error)")
            return nil
        }
    }

    func deletePhoto(_ photo: Photo) {
        deletePhotoCallCount += 1
        viewContext.delete(photo)
    }
    
    func createFeedback(for photo: Photo) -> AIFeedback {
        createFeedbackCallCount += 1
        
        let feedback = AIFeedback(context: viewContext)
        feedback.id = UUID()
        feedback.photoId = photo.id
        feedback.createdAt = Date()
        feedback.isComplete = false
        
        return feedback
    }
    
    func updateFeedback(_ feedback: AIFeedback, content: String, isComplete: Bool, responseId: String? = nil) {
        updateFeedbackCallCount += 1

        feedback.content = content
        feedback.isComplete = isComplete
        if let responseId = responseId {
            feedback.responseId = responseId
        }
    }
    
    func fetchFeedback(for photo: Photo) -> AIFeedback? {
        fetchFeedbackCallCount += 1
        
        let request: NSFetchRequest<AIFeedback> = AIFeedback.fetchRequest()
        request.predicate = NSPredicate(format: "photoId == %@", photo.id! as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            return results.first
        } catch {
            print("Failed to fetch feedback: \(error)")
            return nil
        }
    }
    
    // Test helper methods
    func reset() {
        let photoRequest: NSFetchRequest<NSFetchRequestResult> = Photo.fetchRequest()
        let feedbackRequest: NSFetchRequest<NSFetchRequestResult> = AIFeedback.fetchRequest()
        
        let deletePhotoRequest = NSBatchDeleteRequest(fetchRequest: photoRequest)
        let deleteFeedbackRequest = NSBatchDeleteRequest(fetchRequest: feedbackRequest)
        
        do {
            try viewContext.execute(deletePhotoRequest)
            try viewContext.execute(deleteFeedbackRequest)
            try viewContext.save()
        } catch {
            print("Failed to reset mock data: \(error)")
        }
        
        // Reset call counts
        saveCallCount = 0
        createPhotoCallCount = 0
        fetchPhotosCallCount = 0
        fetchPhotoByIdCallCount = 0
        deletePhotoCallCount = 0
        createFeedbackCallCount = 0
        updateFeedbackCallCount = 0
        fetchFeedbackCallCount = 0
        shouldFailSave = false
        saveError = nil
    }
    
    var photoCount: Int {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        do {
            return try viewContext.count(for: request)
        } catch {
            return 0
        }
    }
    
    var feedbackCount: Int {
        let request: NSFetchRequest<AIFeedback> = AIFeedback.fetchRequest()
        do {
            return try viewContext.count(for: request)
        } catch {
            return 0
        }
    }
}