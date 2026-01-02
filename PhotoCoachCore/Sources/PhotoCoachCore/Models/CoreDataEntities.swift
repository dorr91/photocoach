import Foundation
import CoreData

// MARK: - CoreData Entity Stubs
// These are minimal stubs to allow compilation when CoreData entities aren't available
// The actual entities will be generated from the .xcdatamodeld file

// CoreData entity classes for PhotoCoachCore package
// These provide the interface for entities generated from .xcdatamodeld
@objc(Photo)
public class Photo: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var imagePath: String?
    @NSManaged public var thumbnailPath: String?
    @NSManaged public var capturedAt: Date?
}

@objc(AIFeedback)
public class AIFeedback: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var content: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var isComplete: Bool
    @NSManaged public var photoId: UUID?
}