# PhotoCoach Testing Guidelines

## Core Principles

### Test What Matters
- Focus on user-facing behavior, not implementation details
- Prioritize critical paths: capture → analyze → display feedback
- Test edge cases and error scenarios

### Keep Tests Fast & Reliable
- Mock external dependencies (API, Camera, FileManager)
- Use in-memory Core Data for database tests
- Avoid UI tests except for critical flows

## Test Architecture

### Unit Tests
**Target:** Business logic in ViewModels and Services
```swift
// Example: test_whenAPIKeyMissing_shouldShowError()
```

### Integration Tests
**Target:** Data flow between components
- Core Data persistence
- Photo storage operations
- Settings synchronization

### UI Tests
**Target:** Critical user journeys only
- First-time setup flow
- Photo capture → feedback cycle

## Key Patterns

### Dependency Injection
```swift
protocol OpenAIServiceProtocol {
    func analyzePhoto(_ data: Data) async throws -> PhotoAnalysis
}

// In ViewModel
init(openAI: OpenAIServiceProtocol = OpenAIService()) {
    self.openAI = openAI
}
```

### Mock Helpers
```swift
class MockOpenAIService: OpenAIServiceProtocol {
    var mockResponse: PhotoAnalysis?
    var shouldThrow = false
}
```

### Async Testing
```swift
func test_photoAnalysis() async throws {
    // Given
    let mockService = MockOpenAIService()
    mockService.mockResponse = testAnalysis
    
    // When
    let result = await viewModel.analyzePhoto(testData)
    
    // Then
    XCTAssertEqual(result, testAnalysis)
}
```

## Testing Checklist

### High Priority
- [ ] Photo analysis with valid/invalid API key
- [ ] Core Data save/fetch/delete operations
- [ ] Error handling (network, permissions, storage)
- [ ] Settings persistence

### Medium Priority
- [ ] Photo capture flow
- [ ] Grid overlay calculations
- [ ] Composition guideline detection

### Low Priority
- [ ] UI animations
- [ ] Non-critical UI elements

## Naming Convention
```swift
test_whenCondition_shouldExpectedBehavior()
test_givenState_whenAction_thenResult()
```

## How to Run Tests

**Fast unit tests**: `cd PhotoCoachCore && swift test` (tests business logic without simulator)  
**Integration tests**: Use Xcode Test Navigator (⌘6) or `xcodebuild test -scheme PhotoCoach`

## Quick Tips
1. One assertion per test when possible
2. Use `XCTUnwrap` instead of force unwrapping
3. Clean up test data in `tearDown()`
4. Share test utilities via test target extensions
5. Mock time-dependent operations
6. Run `swift test` frequently during development for instant feedback