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
        guard let imageData = testImage.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to create test image data")
            return
        }
        
        let testPhoto = PhotoTestBuilder()
            .withImagePath("test_photo.jpg")
            .build(in: mockCoreData.viewContext)
        
        // Setup mocks
        mockPhotoStorage.savePhoto(testImage, id: testPhoto.id!)
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
        let testPhoto = PhotoTestBuilder()
            .withImagePath("test_photo.jpg")
            .build(in: mockCoreData.viewContext)
        
        mockPhotoStorage.savePhoto(testImage, id: testPhoto.id!)
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
        let testPhoto = PhotoTestBuilder()
            .withImagePath("test_photo.jpg")
            .build(in: mockCoreData.viewContext)
        
        mockPhotoStorage.savePhoto(testImage, id: testPhoto.id!)
        mockOpenAI.mockStreamResponses = ["Complete feedback"]
        
        // When
        await viewModel.analyzePhoto(testPhoto)
        
        // Allow streaming to complete
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        // Then
        assertCalled(mockCoreData.createFeedbackCallCount, for: "coreData.createFeedback")
        XCTAssertGreaterThan(mockCoreData.updateFeedbackCallCount, 0, "Should update feedback during streaming")
        assertCalled(mockCoreData.saveCallCount, for: "coreData.save")
        
        // Verify feedback was created for the correct photo
        let feedback = mockCoreData.fetchFeedback(for: testPhoto)
        XCTAssertNotNil(feedback, "Feedback should be created in Core Data")
        XCTAssertEqual(feedback?.photoId, testPhoto.id, "Feedback should reference correct photo")
    }
    
    func test_analyzePhoto_shouldUpdateFeedbackDuringStreaming() async {
        // Given
        let testImage = UIImage() // Mock image for testing
        let testPhoto = PhotoTestBuilder()
            .withImagePath("test_photo.jpg")
            .build(in: mockCoreData.viewContext)
        
        mockPhotoStorage.savePhoto(testImage, id: testPhoto.id!)
        
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
        
        // Then
        XCTAssertEqual(mockCoreData.updateFeedbackCallCount, streamResponses.count, 
                      "Should update feedback for each streaming chunk")
        
        let feedback = mockCoreData.fetchFeedback(for: testPhoto)
        XCTAssertEqual(feedback?.content, "This is a great photo", "Final feedback should have complete text")
        XCTAssertTrue(feedback?.isComplete == true, "Feedback should be marked as complete")
    }
    
    // MARK: - Multiple Analysis Tests
    
    func test_analyzePhoto_multipleCalls_shouldHandleCorrectly() async {
        // Given
        let testImage = UIImage() // Mock image for testing
        let testPhoto1 = PhotoTestBuilder().withImagePath("photo1.jpg").build(in: mockCoreData.viewContext)
        let testPhoto2 = PhotoTestBuilder().withImagePath("photo2.jpg").build(in: mockCoreData.viewContext)
        
        mockPhotoStorage.savePhoto(testImage, id: testPhoto1.id!)
        mockPhotoStorage.savePhoto(testImage, id: testPhoto2.id!)
        
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
        XCTAssertEqual(mockCoreData.createFeedbackCallCount, 2, "Should create feedback for both photos")
        
        let feedback1 = mockCoreData.fetchFeedback(for: testPhoto1)
        let feedback2 = mockCoreData.fetchFeedback(for: testPhoto2)
        
        XCTAssertNotNil(feedback1, "First photo should have feedback")
        XCTAssertNotNil(feedback2, "Second photo should have feedback")
        XCTAssertNotEqual(feedback1?.content, feedback2?.content, "Feedback should be different for each photo")
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
        let testPhoto = PhotoTestBuilder().build(in: mockCoreData.viewContext)
        mockPhotoStorage.savePhoto(testImage, id: testPhoto.id!)
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