import Foundation
import CoreData
@testable import PhotoCoach

// MARK: - Test Data Builders

struct TestDataBuilder {
    // Create simple test image data without requiring UIKit
    static func createTestImageData(size: Int = 1024) -> Data {
        return Data.mockImageData(size: size)
    }
    
    static func createTestPhoto(
        context: NSManagedObjectContext,
        id: UUID = UUID(),
        imagePath: String? = nil,
        thumbnailPath: String? = nil,
        capturedAt: Date = Date()
    ) -> Photo {
        let photo = Photo(context: context)
        photo.id = id
        photo.imagePath = imagePath ?? "test_image_\(id.uuidString).jpg"
        photo.thumbnailPath = thumbnailPath ?? "test_thumb_\(id.uuidString).jpg"
        photo.capturedAt = capturedAt
        return photo
    }
    
    static func createTestFeedback(
        context: NSManagedObjectContext,
        id: UUID = UUID(),
        photoId: UUID,
        content: String = "Test feedback content",
        isComplete: Bool = false,
        createdAt: Date = Date()
    ) -> AIFeedback {
        let feedback = AIFeedback(context: context)
        feedback.id = id
        feedback.photoId = photoId
        feedback.content = content
        feedback.isComplete = isComplete
        feedback.createdAt = createdAt
        return feedback
    }
    
    static func createTestServiceContainer(inMemory: Bool = true) -> ServiceContainer {
        return ServiceContainer(inMemory: inMemory)
    }
    
    static func createMockServiceContainer() -> ServiceContainer {
        let mockKeychain = MockKeychainService()
        let mockPhotoStorage = MockPhotoStorage()
        let mockCoreData = MockCoreDataStack()
        let mockOpenAI = MockOpenAIService()
        
        return ServiceContainer(
            keychainService: mockKeychain,
            photoStorage: mockPhotoStorage,
            coreDataStack: mockCoreData,
            openAIService: mockOpenAI
        )
    }
}

// MARK: - Photo Test Builder

class PhotoTestBuilder {
    private var id = UUID()
    private var imagePath: String?
    private var thumbnailPath: String?
    private var capturedAt = Date()
    
    func withId(_ id: UUID) -> PhotoTestBuilder {
        self.id = id
        return self
    }
    
    func withImagePath(_ path: String) -> PhotoTestBuilder {
        self.imagePath = path
        return self
    }
    
    func withThumbnailPath(_ path: String) -> PhotoTestBuilder {
        self.thumbnailPath = path
        return self
    }
    
    func withCapturedAt(_ date: Date) -> PhotoTestBuilder {
        self.capturedAt = date
        return self
    }
    
    func withPastDate(daysAgo: Int) -> PhotoTestBuilder {
        self.capturedAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return self
    }
    
    func build(in context: NSManagedObjectContext) -> Photo {
        return TestDataBuilder.createTestPhoto(
            context: context,
            id: id,
            imagePath: imagePath,
            thumbnailPath: thumbnailPath,
            capturedAt: capturedAt
        )
    }
}

// MARK: - Feedback Test Builder

class FeedbackTestBuilder {
    private var id = UUID()
    private var photoId: UUID
    private var content = "Test feedback content"
    private var isComplete = false
    private var createdAt = Date()
    
    init(photoId: UUID) {
        self.photoId = photoId
    }
    
    func withId(_ id: UUID) -> FeedbackTestBuilder {
        self.id = id
        return self
    }
    
    func withContent(_ content: String) -> FeedbackTestBuilder {
        self.content = content
        return self
    }
    
    func asComplete() -> FeedbackTestBuilder {
        self.isComplete = true
        return self
    }
    
    func asIncomplete() -> FeedbackTestBuilder {
        self.isComplete = false
        return self
    }
    
    func withCreatedAt(_ date: Date) -> FeedbackTestBuilder {
        self.createdAt = date
        return self
    }
    
    func build(in context: NSManagedObjectContext) -> AIFeedback {
        return TestDataBuilder.createTestFeedback(
            context: context,
            id: id,
            photoId: photoId,
            content: content,
            isComplete: isComplete,
            createdAt: createdAt
        )
    }
}

// MARK: - Stream Response Builder

struct StreamResponseBuilder {
    static func singleResponse(_ text: String) -> [String] {
        return [text]
    }
    
    static func multipleResponses(_ texts: String...) -> [String] {
        return texts
    }
    
    static func streamedSentence(_ sentence: String) -> [String] {
        let words = sentence.split(separator: " ")
        return words.enumerated().map { index, _ in
            words[0...index].joined(separator: " ")
        }
    }
    
    static func photographyFeedback() -> [String] {
        return [
            "This photo shows",
            "This photo shows good",
            "This photo shows good composition",
            "This photo shows good composition with",
            "This photo shows good composition with excellent lighting.",
            "This photo shows good composition with excellent lighting. The rule of thirds is well applied."
        ]
    }
    
    static func errorResponse() -> Error {
        return NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock API error"])
    }
}

// MARK: - Test Data Extensions

extension Photo {
    static func testPhoto(in context: NSManagedObjectContext) -> Photo {
        return PhotoTestBuilder().build(in: context)
    }
    
    static func testPhotoWithId(_ id: UUID, in context: NSManagedObjectContext) -> Photo {
        return PhotoTestBuilder().withId(id).build(in: context)
    }
}

extension AIFeedback {
    static func testFeedback(for photoId: UUID, in context: NSManagedObjectContext) -> AIFeedback {
        return FeedbackTestBuilder(photoId: photoId).build(in: context)
    }
    
    static func completeFeedback(for photoId: UUID, in context: NSManagedObjectContext) -> AIFeedback {
        return FeedbackTestBuilder(photoId: photoId)
            .asComplete()
            .withContent("Complete test feedback content")
            .build(in: context)
    }
}