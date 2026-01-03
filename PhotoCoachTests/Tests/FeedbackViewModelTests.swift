import XCTest
@testable import PhotoCoach

@MainActor
final class FeedbackViewModelTests: XCTestCase {
    var viewModel: FeedbackViewModel!
    var mockCoreData: MockCoreDataStack!
    var mockOpenAI: MockOpenAIService!
    var mockPhotoStorage: MockPhotoStorage!
    
    override func setUpWithError() throws {
        mockCoreData = MockCoreDataStack()
        mockOpenAI = MockOpenAIService()
        mockPhotoStorage = MockPhotoStorage()
        
        viewModel = FeedbackViewModel(
            coreData: mockCoreData,
            openAIService: mockOpenAI,
            photoStorage: mockPhotoStorage
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockCoreData.reset()
        mockOpenAI = nil
        mockPhotoStorage.reset()
    }
    
    // MARK: - Initial State Tests
    
    func test_initialState_shouldBeIdle() {
        // Then
        XCTAssertEqual(viewModel.state, .idle, "Initial state should be idle")
        XCTAssertEqual(viewModel.displayText, "", "Display text should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertFalse(viewModel.isStreaming, "Should not be streaming initially")
        XCTAssertFalse(viewModel.hasError, "Should not have error initially")
    }
    
    // MARK: - State Property Tests
    
    func test_displayText_whenLoading_shouldReturnEmptyString() {
        // Given
        viewModel.state = .loading
        
        // Then
        XCTAssertEqual(viewModel.displayText, "", "Loading state should show empty text")
    }
    
    func test_displayText_whenStreaming_shouldReturnStreamedText() {
        // Given
        let streamedText = "This is streaming text"
        viewModel.state = .streaming(streamedText)
        
        // Then
        XCTAssertEqual(viewModel.displayText, streamedText, "Streaming state should show streamed text")
    }
    
    func test_displayText_whenComplete_shouldReturnCompleteText() {
        // Given
        let completeText = "This is complete text"
        viewModel.state = .complete(completeText)
        
        // Then
        XCTAssertEqual(viewModel.displayText, completeText, "Complete state should show complete text")
    }
    
    func test_displayText_whenError_shouldReturnErrorMessage() {
        // Given
        let errorMessage = "Something went wrong"
        viewModel.state = .error(errorMessage)
        
        // Then
        XCTAssertEqual(viewModel.displayText, errorMessage, "Error state should show error message")
    }
    
    func test_isLoading_shouldReflectLoadingState() {
        // Given & When & Then
        viewModel.state = .idle
        XCTAssertFalse(viewModel.isLoading)
        
        viewModel.state = .loading
        XCTAssertTrue(viewModel.isLoading)
        
        viewModel.state = .streaming("text")
        XCTAssertFalse(viewModel.isLoading)
        
        viewModel.state = .complete("text")
        XCTAssertFalse(viewModel.isLoading)
        
        viewModel.state = .error("error")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_isStreaming_shouldReflectStreamingState() {
        // Given & When & Then
        viewModel.state = .idle
        XCTAssertFalse(viewModel.isStreaming)
        
        viewModel.state = .loading
        XCTAssertFalse(viewModel.isStreaming)
        
        viewModel.state = .streaming("text")
        XCTAssertTrue(viewModel.isStreaming)
        
        viewModel.state = .complete("text")
        XCTAssertFalse(viewModel.isStreaming)
        
        viewModel.state = .error("error")
        XCTAssertFalse(viewModel.isStreaming)
    }
    
    func test_hasError_shouldReflectErrorState() {
        // Given & When & Then
        viewModel.state = .idle
        XCTAssertFalse(viewModel.hasError)
        
        viewModel.state = .loading
        XCTAssertFalse(viewModel.hasError)
        
        viewModel.state = .streaming("text")
        XCTAssertFalse(viewModel.hasError)
        
        viewModel.state = .complete("text")
        XCTAssertFalse(viewModel.hasError)
        
        viewModel.state = .error("error")
        XCTAssertTrue(viewModel.hasError)
    }
    
    // MARK: - Photo Analysis Tests
    
    func test_analyzePhoto_withValidPhoto_shouldStreamFeedback() async {
        // Given
        let testImage = UIImage() // Mock image for testing
        let photoId = UUID()

        let testPhoto = PhotoTestBuilder()
            .withId(photoId)
            .build(in: mockCoreData.viewContext)

        // Setup mocks - savePhoto returns the actual paths used, update photo to match
        let paths = mockPhotoStorage.savePhoto(testImage, id: photoId)
        testPhoto.imagePath = paths?.imagePath

        let streamResponses = StreamResponseBuilder.photographyFeedback()
        mockOpenAI.mockStreamResponses = streamResponses

        // When
        await viewModel.analyzePhoto(testPhoto)

        // Allow time for streaming to complete
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Then
        assertCalled(mockPhotoStorage.imageDataForAPICallCount, for: "photoStorage.imageDataForAPI")
        assertCalled(mockOpenAI.streamFeedbackCallCount, for: "openAI.streamFeedback")

        // Should eventually reach complete state
        if case .complete(let text) = viewModel.state {
            XCTAssertFalse(text.isEmpty, "Complete state should have feedback text")
        } else {
            XCTFail("Expected complete state but got \(viewModel.state)")
        }
    }
    
    func test_analyzePhoto_whenImageDataUnavailable_shouldShowError() async {
        // Given
        let testPhoto = PhotoTestBuilder()
            .withImagePath("nonexistent.jpg")
            .build(in: mockCoreData.viewContext)
        
        mockPhotoStorage.shouldFailLoad = true
        
        // When
        await viewModel.analyzePhoto(testPhoto)
        
        // Then
        assertCalled(mockPhotoStorage.imageDataForAPICallCount, for: "photoStorage.imageDataForAPI")
        assertNotCalled(mockOpenAI.streamFeedbackCallCount, for: "openAI.streamFeedback")
        
        if case .error(let errorMessage) = viewModel.state {
            XCTAssertFalse(errorMessage.isEmpty, "Error state should have error message")
        } else {
            XCTFail("Expected error state but got \(viewModel.state)")
        }
    }
    
    func test_analyzePhoto_whenAPIThrowsError_shouldShowError() async {
        // Given
        let testImage = UIImage() // Mock image for testing
        let photoId = UUID()

        let testPhoto = PhotoTestBuilder()
            .withId(photoId)
            .build(in: mockCoreData.viewContext)

        let paths = mockPhotoStorage.savePhoto(testImage, id: photoId)
        testPhoto.imagePath = paths?.imagePath
        mockOpenAI.shouldThrowError = StreamResponseBuilder.errorResponse()

        // When
        await viewModel.analyzePhoto(testPhoto)

        // Allow time for error to propagate
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then
        assertCalled(mockPhotoStorage.imageDataForAPICallCount, for: "photoStorage.imageDataForAPI")
        assertCalled(mockOpenAI.streamFeedbackCallCount, for: "openAI.streamFeedback")

        if case .error = viewModel.state {
            XCTAssertTrue(viewModel.hasError, "Should be in error state")
        } else {
            XCTFail("Expected error state but got \(viewModel.state)")
        }
    }
    
    // MARK: - State Persistence Tests
    
    func test_analyzePhoto_shouldCreateAndUpdateFeedbackInCoreData() async {
        // Given
        let testImage = UIImage() // Mock image for testing
        let photoId = UUID()

        let testPhoto = PhotoTestBuilder()
            .withId(photoId)
            .build(in: mockCoreData.viewContext)

        let paths = mockPhotoStorage.savePhoto(testImage, id: photoId)
        testPhoto.imagePath = paths?.imagePath

        // Pre-create feedback (ViewModel only updates, doesn't create)
        let feedback = mockCoreData.createFeedback(for: testPhoto)
        mockCoreData.save()

        mockOpenAI.mockStreamResponses = ["Complete feedback"]

        // When
        await viewModel.analyzePhoto(testPhoto)

        // Allow streaming to complete
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

        // Then
        XCTAssertGreaterThan(mockCoreData.updateFeedbackCallCount, 0, "Should update feedback during streaming")

        // Verify feedback was updated for the correct photo
        let fetchedFeedback = mockCoreData.fetchFeedback(for: testPhoto)
        XCTAssertNotNil(fetchedFeedback, "Feedback should exist in Core Data")
        XCTAssertEqual(fetchedFeedback?.photoId, testPhoto.id, "Feedback should reference correct photo")
        XCTAssertEqual(fetchedFeedback?.content, "Complete feedback", "Feedback should have streamed content")
        XCTAssertTrue(fetchedFeedback?.isComplete == true, "Feedback should be marked complete")
    }
    
    func test_analyzePhoto_shouldUpdateFeedbackDuringStreaming() async {
        // Given
        let testImage = UIImage() // Mock image for testing
        let photoId = UUID()

        let testPhoto = PhotoTestBuilder()
            .withId(photoId)
            .build(in: mockCoreData.viewContext)

        let paths = mockPhotoStorage.savePhoto(testImage, id: photoId)
        testPhoto.imagePath = paths?.imagePath

        // Pre-create feedback (ViewModel only updates, doesn't create)
        _ = mockCoreData.createFeedback(for: testPhoto)
        mockCoreData.save()

        let streamResponses = [
            "This",
            "This is",
            "This is a great",
            "This is a great photo"
        ]
        mockOpenAI.mockStreamResponses = streamResponses

        // When
        await viewModel.analyzePhoto(testPhoto)

        // Allow streaming to complete
        try? await Task.sleep(nanoseconds: 400_000_000) // 400ms

        // Then - ViewModel updates once at the end, not for each chunk
        XCTAssertGreaterThan(mockCoreData.updateFeedbackCallCount, 0, "Should update feedback")

        let feedback = mockCoreData.fetchFeedback(for: testPhoto)
        XCTAssertEqual(feedback?.content, "ThisThis isThis is a greatThis is a great photo", "Final feedback should have accumulated text")
        XCTAssertTrue(feedback?.isComplete == true, "Feedback should be marked as complete")
    }
    
    // MARK: - Multiple Analysis Tests
    
    func test_analyzePhoto_multipleCalls_shouldHandleCorrectly() async {
        // Given
        let testImage = UIImage() // Mock image for testing
        let photoId1 = UUID()
        let photoId2 = UUID()

        let testPhoto1 = PhotoTestBuilder().withId(photoId1).build(in: mockCoreData.viewContext)
        let testPhoto2 = PhotoTestBuilder().withId(photoId2).build(in: mockCoreData.viewContext)

        let paths1 = mockPhotoStorage.savePhoto(testImage, id: photoId1)
        let paths2 = mockPhotoStorage.savePhoto(testImage, id: photoId2)
        testPhoto1.imagePath = paths1?.imagePath
        testPhoto2.imagePath = paths2?.imagePath

        // Pre-create feedback for both photos (ViewModel only updates, doesn't create)
        _ = mockCoreData.createFeedback(for: testPhoto1)
        _ = mockCoreData.createFeedback(for: testPhoto2)
        mockCoreData.save()

        // When
        // First analysis
        mockOpenAI.mockStreamResponses = ["First photo analysis"]
        await viewModel.analyzePhoto(testPhoto1)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Second analysis
        mockOpenAI.reset()
        mockOpenAI.mockStreamResponses = ["Second photo analysis"]
        await viewModel.analyzePhoto(testPhoto2)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then
        let feedback1 = mockCoreData.fetchFeedback(for: testPhoto1)
        let feedback2 = mockCoreData.fetchFeedback(for: testPhoto2)

        XCTAssertNotNil(feedback1, "First photo should have feedback")
        XCTAssertNotNil(feedback2, "Second photo should have feedback")
        XCTAssertEqual(feedback1?.content, "First photo analysis", "First feedback should have correct content")
        XCTAssertEqual(feedback2?.content, "Second photo analysis", "Second feedback should have correct content")
    }
    
    // MARK: - Reset Tests
    
    func test_resetState_shouldReturnToIdle() {
        // Given
        viewModel.state = .complete("Some feedback")
        XCTAssertNotEqual(viewModel.state, .idle)
        
        // When
        viewModel.resetState()
        
        // Then
        XCTAssertEqual(viewModel.state, .idle, "State should reset to idle")
        XCTAssertEqual(viewModel.displayText, "", "Display text should be empty after reset")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after reset")
        XCTAssertFalse(viewModel.hasError, "Should not have error after reset")
    }
    
    // MARK: - Performance Tests
    
    func test_analyzePhoto_performance() async {
        // Given
        let testImage = UIImage() // Mock image for testing
        let photoId = UUID()
        let testPhoto = PhotoTestBuilder().withId(photoId).build(in: mockCoreData.viewContext)

        let paths = mockPhotoStorage.savePhoto(testImage, id: photoId)
        testPhoto.imagePath = paths?.imagePath
        mockOpenAI.mockStreamResponses = ["Quick feedback"]
        mockOpenAI.streamDelayMilliseconds = 1 // Minimal delay for performance test

        // When & Then
        let startTime = Date()
        await viewModel.analyzePhoto(testPhoto)
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(duration, 1.0, "Analysis should complete quickly in tests")
    }
    
    // MARK: - Edge Cases
    
    func test_analyzePhoto_withEmptyImagePath_shouldHandleGracefully() async {
        // Given
        let testPhoto = PhotoTestBuilder()
            .withImagePath("")
            .build(in: mockCoreData.viewContext)
        
        // When
        await viewModel.analyzePhoto(testPhoto)
        
        // Then
        if case .error = viewModel.state {
            XCTAssertTrue(viewModel.hasError, "Should handle empty image path as error")
        } else {
            XCTFail("Expected error state for empty image path")
        }
    }
    
    func test_analyzePhoto_withNilImagePath_shouldHandleGracefully() async {
        // Given
        let testPhoto = PhotoTestBuilder().build(in: mockCoreData.viewContext)
        testPhoto.imagePath = nil
        
        // When
        await viewModel.analyzePhoto(testPhoto)
        
        // Then
        if case .error = viewModel.state {
            XCTAssertTrue(viewModel.hasError, "Should handle nil image path as error")
        } else {
            XCTFail("Expected error state for nil image path")
        }
    }
}