import XCTest
import CoreData
@testable import PhotoCoach

final class CoreDataStackTests: XCTestCase {
    var coreDataStack: MockCoreDataStack!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        coreDataStack = MockCoreDataStack()
        context = coreDataStack.viewContext
    }
    
    override func tearDownWithError() throws {
        coreDataStack.reset()
        coreDataStack = nil
        context = nil
    }
    
    // MARK: - Photo CRUD Tests
    
    func test_createPhoto_shouldCreatePhotoWithCorrectProperties() {
        // Given
        let imagePath = "test_image.jpg"
        let thumbnailPath = "test_thumb.jpg"
        
        // When
        let photo = coreDataStack.createPhoto(imagePath: imagePath, thumbnailPath: thumbnailPath)
        
        // Then
        XCTAssertNotNil(photo.id, "Photo should have an ID")
        XCTAssertEqual(photo.imagePath, imagePath, "Photo should have correct image path")
        XCTAssertEqual(photo.thumbnailPath, thumbnailPath, "Photo should have correct thumbnail path")
        XCTAssertNotNil(photo.capturedAt, "Photo should have a capture date")
        assertCallCount(coreDataStack.createPhotoCallCount, equals: 1, for: "createPhoto")
    }
    
    func test_fetchPhotos_whenEmpty_shouldReturnEmptyArray() {
        // When
        let photos = coreDataStack.fetchPhotos()
        
        // Then
        XCTAssertTrue(photos.isEmpty, "Should return empty array when no photos exist")
        assertCallCount(coreDataStack.fetchPhotosCallCount, equals: 1, for: "fetchPhotos")
    }
    
    func test_fetchPhotos_whenPhotosExist_shouldReturnSortedPhotos() {
        // Given
        let olderDate = testDate(daysFromNow: -2)
        let newerDate = testDate(daysFromNow: -1)
        
        let photo1 = PhotoTestBuilder()
            .withCapturedAt(olderDate)
            .withImagePath("older_photo.jpg")
            .build(in: context)
        
        let photo2 = PhotoTestBuilder()
            .withCapturedAt(newerDate)
            .withImagePath("newer_photo.jpg")
            .build(in: context)
        
        coreDataStack.save()
        
        // When
        let photos = coreDataStack.fetchPhotos()
        
        // Then
        XCTAssertEqual(photos.count, 2, "Should return both photos")
        XCTAssertEqual(photos[0].imagePath, "newer_photo.jpg", "Newer photo should be first (sorted descending)")
        XCTAssertEqual(photos[1].imagePath, "older_photo.jpg", "Older photo should be second")
    }
    
    func test_deletePhoto_shouldRemovePhotoFromContext() {
        // Given
        let photo = PhotoTestBuilder().build(in: context)
        coreDataStack.save()
        
        // Verify photo exists
        let photosBeforeDelete = coreDataStack.fetchPhotos()
        XCTAssertEqual(photosBeforeDelete.count, 1)
        
        // When
        coreDataStack.deletePhoto(photo)
        coreDataStack.save()
        
        // Then
        let photosAfterDelete = coreDataStack.fetchPhotos()
        XCTAssertEqual(photosAfterDelete.count, 0, "Photo should be deleted")
        assertCallCount(coreDataStack.deletePhotoCallCount, equals: 1, for: "deletePhoto")
    }
    
    // MARK: - Feedback CRUD Tests
    
    func test_createFeedback_shouldCreateFeedbackWithCorrectProperties() {
        // Given
        let photo = PhotoTestBuilder().build(in: context)
        
        // When
        let feedback = coreDataStack.createFeedback(for: photo)
        
        // Then
        XCTAssertNotNil(feedback.id, "Feedback should have an ID")
        XCTAssertEqual(feedback.photoId, photo.id, "Feedback should reference the correct photo")
        XCTAssertNotNil(feedback.createdAt, "Feedback should have a creation date")
        XCTAssertFalse(feedback.isComplete, "Feedback should start as incomplete")
        assertCallCount(coreDataStack.createFeedbackCallCount, equals: 1, for: "createFeedback")
    }
    
    func test_updateFeedback_shouldUpdateContentAndCompletionStatus() {
        // Given
        let photo = PhotoTestBuilder().build(in: context)
        let feedback = coreDataStack.createFeedback(for: photo)
        let newContent = "Updated feedback content"
        
        // When
        coreDataStack.updateFeedback(feedback, content: newContent, isComplete: true)
        
        // Then
        XCTAssertEqual(feedback.content, newContent, "Feedback content should be updated")
        XCTAssertTrue(feedback.isComplete, "Feedback should be marked as complete")
        assertCallCount(coreDataStack.updateFeedbackCallCount, equals: 1, for: "updateFeedback")
    }
    
    func test_fetchFeedback_whenNoFeedbackExists_shouldReturnNil() {
        // Given
        let photo = PhotoTestBuilder().build(in: context)
        
        // When
        let feedback = coreDataStack.fetchFeedback(for: photo)
        
        // Then
        XCTAssertNil(feedback, "Should return nil when no feedback exists")
        assertCallCount(coreDataStack.fetchFeedbackCallCount, equals: 1, for: "fetchFeedback")
    }
    
    func test_fetchFeedback_whenFeedbackExists_shouldReturnCorrectFeedback() {
        // Given
        let photo = PhotoTestBuilder().build(in: context)
        let createdFeedback = coreDataStack.createFeedback(for: photo)
        coreDataStack.updateFeedback(createdFeedback, content: "Test feedback", isComplete: false)
        coreDataStack.save()
        
        // When
        let fetchedFeedback = coreDataStack.fetchFeedback(for: photo)
        
        // Then
        XCTAssertNotNil(fetchedFeedback, "Should return feedback when it exists")
        XCTAssertEqual(fetchedFeedback?.id, createdFeedback.id, "Should return the correct feedback")
        XCTAssertEqual(fetchedFeedback?.content, "Test feedback", "Should have correct content")
        XCTAssertEqual(fetchedFeedback?.photoId, photo.id, "Should reference correct photo")
    }
    
    func test_fetchFeedback_withMultiplePhotos_shouldReturnCorrectFeedback() {
        // Given
        let photo1 = PhotoTestBuilder().withImagePath("photo1.jpg").build(in: context)
        let photo2 = PhotoTestBuilder().withImagePath("photo2.jpg").build(in: context)
        
        let feedback1 = coreDataStack.createFeedback(for: photo1)
        let feedback2 = coreDataStack.createFeedback(for: photo2)
        
        coreDataStack.updateFeedback(feedback1, content: "Feedback for photo 1", isComplete: true)
        coreDataStack.updateFeedback(feedback2, content: "Feedback for photo 2", isComplete: false)
        coreDataStack.save()
        
        // When
        let fetchedFeedback1 = coreDataStack.fetchFeedback(for: photo1)
        let fetchedFeedback2 = coreDataStack.fetchFeedback(for: photo2)
        
        // Then
        XCTAssertEqual(fetchedFeedback1?.content, "Feedback for photo 1", "Should fetch correct feedback for photo1")
        XCTAssertEqual(fetchedFeedback2?.content, "Feedback for photo 2", "Should fetch correct feedback for photo2")
        XCTAssertTrue(fetchedFeedback1?.isComplete == true, "Photo1 feedback should be complete")
        XCTAssertFalse(fetchedFeedback2?.isComplete == true, "Photo2 feedback should be incomplete")
    }
    
    // MARK: - Save Tests
    
    func test_save_whenSuccessful_shouldPersistChanges() {
        // Given
        let photo = PhotoTestBuilder().build(in: context)
        let initialCount = coreDataStack.photoCount
        
        // When
        coreDataStack.save()
        
        // Then
        let finalCount = coreDataStack.photoCount
        XCTAssertEqual(finalCount, initialCount + 1, "Photo should be persisted after save")
        assertCallCount(coreDataStack.saveCallCount, equals: 1, for: "save")
    }
    
    func test_save_whenFails_shouldHandleGracefully() {
        // Given
        coreDataStack.shouldFailSave = true
        coreDataStack.saveError = NSError(domain: "TestError", code: 1)
        let photo = PhotoTestBuilder().build(in: context)
        
        // When
        coreDataStack.save() // Should not crash
        
        // Then
        assertCallCount(coreDataStack.saveCallCount, equals: 1, for: "save")
        // The mock handles the error gracefully without crashing
    }
    
    // MARK: - Integration Tests
    
    func test_fullPhotoFeedbackWorkflow() {
        // Given - Create a photo
        let photo = coreDataStack.createPhoto(imagePath: "workflow_test.jpg", thumbnailPath: "workflow_thumb.jpg")
        coreDataStack.save()
        
        // When - Create feedback for the photo
        let feedback = coreDataStack.createFeedback(for: photo)
        coreDataStack.updateFeedback(feedback, content: "Great composition!", isComplete: false)
        coreDataStack.save()
        
        // Update feedback to complete
        coreDataStack.updateFeedback(feedback, content: "Great composition! Well done.", isComplete: true)
        coreDataStack.save()
        
        // Then - Verify the complete workflow
        let fetchedPhotos = coreDataStack.fetchPhotos()
        XCTAssertEqual(fetchedPhotos.count, 1, "Should have one photo")
        
        let fetchedPhoto = fetchedPhotos[0]
        let fetchedFeedback = coreDataStack.fetchFeedback(for: fetchedPhoto)
        
        XCTAssertNotNil(fetchedFeedback, "Should have feedback for the photo")
        XCTAssertEqual(fetchedFeedback?.content, "Great composition! Well done.", "Should have final feedback content")
        XCTAssertTrue(fetchedFeedback?.isComplete == true, "Feedback should be complete")
        
        // Clean up - Delete photo
        coreDataStack.deletePhoto(fetchedPhoto)
        coreDataStack.save()
        
        let finalPhotos = coreDataStack.fetchPhotos()
        XCTAssertEqual(finalPhotos.count, 0, "Photo should be deleted")
        
        // Note: In a real app, feedback might be cascaded deleted or handled separately
        // This depends on the Core Data model relationships
    }
    
    // MARK: - Performance Tests
    
    func test_createAndFetchManyPhotos_performance() {
        measure {
            // Create multiple photos
            for i in 0..<100 {
                let photo = coreDataStack.createPhoto(
                    imagePath: "perf_test_\(i).jpg",
                    thumbnailPath: "perf_thumb_\(i).jpg"
                )
                _ = coreDataStack.createFeedback(for: photo)
            }
            coreDataStack.save()
            
            // Fetch all photos
            _ = coreDataStack.fetchPhotos()
            
            // Clean up
            coreDataStack.reset()
        }
    }
    
    func test_bulkFeedbackOperations_performance() {
        // Given
        var photos: [Photo] = []
        for i in 0..<50 {
            let photo = coreDataStack.createPhoto(
                imagePath: "bulk_test_\(i).jpg",
                thumbnailPath: "bulk_thumb_\(i).jpg"
            )
            photos.append(photo)
        }
        coreDataStack.save()
        
        measure {
            // Create and update feedback for all photos
            for (index, photo) in photos.enumerated() {
                let feedback = coreDataStack.createFeedback(for: photo)
                coreDataStack.updateFeedback(
                    feedback,
                    content: "Performance test feedback \(index)",
                    isComplete: index % 2 == 0
                )
            }
            coreDataStack.save()
            
            // Fetch feedback for all photos
            for photo in photos {
                _ = coreDataStack.fetchFeedback(for: photo)
            }
        }
    }
}