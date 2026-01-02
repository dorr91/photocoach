# Protocol Abstractions

This directory contains protocol definitions for all services in the PhotoCoach app. These protocols enable:

1. **Dependency Injection**: ViewModels can accept protocol types instead of concrete implementations
2. **Testability**: Mock implementations can be created for unit testing
3. **Decoupling**: Reduces tight coupling between components

## Protocols

- `OpenAIServiceProtocol`: Defines the interface for AI photo analysis
- `PhotoStorageProtocol`: Defines file storage operations for photos
- `KeychainServiceProtocol`: Defines secure storage for API keys
- `CoreDataStackProtocol`: Defines Core Data operations
- `FileManagerProtocol`: Wraps FileManager for mockability
- `URLSessionProtocol`: Wraps URLSession for network testing

## Usage

Services will be updated to conform to these protocols in the next step, maintaining backward compatibility.