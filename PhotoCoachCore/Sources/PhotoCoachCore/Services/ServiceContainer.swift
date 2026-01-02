import Foundation

// ServiceContainer manages all service dependencies for the app
public class ServiceContainer: ObservableObject {
    public let keychainService: KeychainServiceProtocol
    public let photoStorage: PhotoStorageProtocol
    public let coreDataStack: CoreDataStackProtocol
    public let openAIService: OpenAIServiceType
    
    public init(inMemory: Bool = false) {
        self.keychainService = KeychainService()
        self.photoStorage = PhotoStorageService()
        self.coreDataStack = SimpleCoreDataStack(inMemory: inMemory)
        self.openAIService = OpenAIServiceWrapper(keychainService: KeychainService())
    }
    
    // Test initializer
    public init(keychainService: KeychainServiceProtocol,
         photoStorage: PhotoStorageProtocol,
         coreDataStack: CoreDataStackProtocol,
         openAIService: OpenAIServiceType) {
        self.keychainService = keychainService
        self.photoStorage = photoStorage
        self.coreDataStack = coreDataStack
        self.openAIService = openAIService
    }
}