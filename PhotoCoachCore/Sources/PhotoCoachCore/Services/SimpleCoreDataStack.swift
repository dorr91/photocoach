import Foundation
import CoreData

// Minimal CoreDataStack implementation for Swift Package
// This provides basic functionality for testing and framework building
public class SimpleCoreDataStack: CoreDataStackProtocol {
    private let inMemory: Bool
    
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private lazy var persistentContainer: NSPersistentContainer = {
        // Try to find the model in the Swift Package bundle
        let bundle = Bundle.module
        var managedObjectModel: NSManagedObjectModel?
        
        // Try different paths to find the model
        if let modelURL = bundle.url(forResource: "PhotoCoach", withExtension: "momd") {
            managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
            if managedObjectModel == nil {
                print("Found .momd file but failed to load model from: \(modelURL)")
            }
        } else if let modelURL = bundle.url(forResource: "PhotoCoach", withExtension: "xcdatamodeld") {
            managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
            if managedObjectModel == nil {
                print("Found .xcdatamodeld file but failed to load model from: \(modelURL)")
            }
        }
        
        // Fallback: create minimal model programmatically for testing
        if managedObjectModel == nil {
            print("Using programmatic fallback model for testing")
            managedObjectModel = createMinimalModel()
        }
        
        guard let model = managedObjectModel else {
            fatalError("Failed to load or create PhotoCoach data model")
        }
        
        let container = NSPersistentContainer(name: "PhotoCoach", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("CoreData error: \(error)")
            }
        }
        return container
    }()
    
    public init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }
    
    public func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            try? context.save()
        }
    }
    
    // MARK: - Photo Operations (stub implementations for basic testing)
    
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
        request.sortDescriptors = [NSSortDescriptor(key: "capturedAt", ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching photos: \(error)")
            return []
        }
    }
    
    public func deletePhoto(_ photo: Photo) {
        viewContext.delete(photo)
        save()
    }
    
    // MARK: - Feedback Operations (stub implementations for basic testing)
    
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
    
    private func createMinimalModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create Photo entity
        let photoEntity = NSEntityDescription()
        photoEntity.name = "Photo"
        photoEntity.managedObjectClassName = "Photo"
        
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = true
        
        let imagePathAttribute = NSAttributeDescription()
        imagePathAttribute.name = "imagePath"
        imagePathAttribute.attributeType = .stringAttributeType
        imagePathAttribute.isOptional = true
        
        let thumbnailPathAttribute = NSAttributeDescription()
        thumbnailPathAttribute.name = "thumbnailPath"
        thumbnailPathAttribute.attributeType = .stringAttributeType
        thumbnailPathAttribute.isOptional = true
        
        let capturedAtAttribute = NSAttributeDescription()
        capturedAtAttribute.name = "capturedAt"
        capturedAtAttribute.attributeType = .dateAttributeType
        capturedAtAttribute.isOptional = true
        
        photoEntity.properties = [idAttribute, imagePathAttribute, thumbnailPathAttribute, capturedAtAttribute]
        
        // Create AIFeedback entity
        let feedbackEntity = NSEntityDescription()
        feedbackEntity.name = "AIFeedback"
        feedbackEntity.managedObjectClassName = "AIFeedback"
        
        let feedbackIdAttribute = NSAttributeDescription()
        feedbackIdAttribute.name = "id"
        feedbackIdAttribute.attributeType = .UUIDAttributeType
        feedbackIdAttribute.isOptional = true
        
        let contentAttribute = NSAttributeDescription()
        contentAttribute.name = "content"
        contentAttribute.attributeType = .stringAttributeType
        contentAttribute.isOptional = true
        
        let photoIdAttribute = NSAttributeDescription()
        photoIdAttribute.name = "photoId"
        photoIdAttribute.attributeType = .UUIDAttributeType
        photoIdAttribute.isOptional = true
        
        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true
        
        let isCompleteAttribute = NSAttributeDescription()
        isCompleteAttribute.name = "isComplete"
        isCompleteAttribute.attributeType = .booleanAttributeType
        isCompleteAttribute.isOptional = true
        
        feedbackEntity.properties = [feedbackIdAttribute, contentAttribute, photoIdAttribute, createdAtAttribute, isCompleteAttribute]
        
        model.entities = [photoEntity, feedbackEntity]
        return model
    }
}