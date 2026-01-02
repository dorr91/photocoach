# Services Architecture

This directory contains all services refactored for full dependency injection and testability.

## Services

### OpenAIService
- Actor-based service for AI photo analysis
- Conforms to `OpenAIServiceProtocol`
- Accepts `URLSessionProtocol` and `KeychainServiceProtocol` via constructor
- Uses `OpenAIServiceWrapper` for non-actor contexts

### KeychainService
- Manages secure API key storage
- Conforms to `KeychainServiceProtocol`
- Replaces static KeychainHelper methods

### PhotoStorageService
- Handles photo file operations
- Conforms to `PhotoStorageProtocol`
- Accepts `FileManagerProtocol` for testability
- Replaces static PhotoStorage methods

### CoreDataStack
- Manages Core Data persistence
- Conforms to `CoreDataStackProtocol`
- Accepts `PhotoStorageProtocol` for file operations

### ServiceContainer
- Central dependency injection container
- Creates and manages all service instances
- Provides test initializer for mock injection

## Usage

### Production
```swift
let container = ServiceContainer()
let viewModel = FeedbackViewModel(
    coreData: container.coreDataStack,
    openAI: container.openAIService,
    storage: container.photoStorage
)
```

### Testing
```swift
let container = ServiceContainer(
    keychainService: MockKeychainService(),
    photoStorage: MockPhotoStorage(),
    coreDataStack: MockCoreDataStack(),
    openAIService: MockOpenAIService()
)
```

## Benefits
- No static singletons
- Full dependency injection
- Easy to mock for testing
- Clear service boundaries
- Type-safe interfaces