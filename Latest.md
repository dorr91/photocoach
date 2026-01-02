# PhotoCoach - Architecture Overview

## What We Built

An AI-powered photo coaching app for iOS. Take a photo → get instant feedback on composition, lighting, and subject from GPT-4 Vision.

## Tech Stack

- **SwiftUI** with MVVM pattern
- **AVFoundation** for camera (bridged to SwiftUI)
- **Core Data** for persistence
- **Keychain** for secure API key storage
- **URLSession** with async/await for streaming API responses

## App Flow

```
┌─────────────┐     tap shutter     ┌──────────────────┐
│ CameraView  │ ──────────────────► │  PhotoReviewView │
│             │                     │                  │
│  [shutter]  │ ◄────── back ────── │  [photo cards]   │
│  [settings] │                     │  [AI feedback]   │
└─────────────┘                     └──────────────────┘
       │
       │ gear icon
       ▼
┌─────────────┐
│ SettingsView│
│             │
│ [API key]   │
└─────────────┘
```

## Project Structure

### Framework-Based Architecture

PhotoCoach now uses a **Swift Package** (PhotoCoachCore) to extract business logic, enabling fast unit tests without simulator overhead:

```
PhotoCoach/
├── PhotoCoachCore/              # 🆕 Swift Package (business logic)
│   ├── Package.swift           # Package manifest
│   ├── Sources/PhotoCoachCore/
│   │   ├── Models/
│   │   │   ├── CoreDataEntities.swift
│   │   │   └── PhotoCoach.xcdatamodeld     # Core Data model
│   │   ├── Protocols/           # Protocol abstractions
│   │   │   ├── CoreDataStackProtocol.swift
│   │   │   ├── KeychainServiceProtocol.swift
│   │   │   ├── PhotoStorageProtocol.swift
│   │   │   ├── OpenAIServiceProtocol.swift
│   │   │   ├── URLSessionProtocol.swift
│   │   │   └── FileManagerProtocol.swift
│   │   ├── Services/            # Testable business logic
│   │   │   ├── KeychainService.swift
│   │   │   ├── PhotoStorageService.swift
│   │   │   ├── SimpleCoreDataStack.swift
│   │   │   ├── MockOpenAIService.swift
│   │   │   └── ServiceContainer.swift     # DI container
│   │   └── ViewModels/          # (Temporarily disabled)
│   └── Tests/PhotoCoachCoreTests/
│       └── BasicPackageTests.swift       # Fast unit tests (~0.07s)
│
├── PhotoCoach/                  # 🔄 iOS App (UI + integration)
│   ├── PhotoCoachApp.swift      # App entry point, uses ServiceContainer
│   ├── ContentView.swift        # Navigation container
│   ├── Camera/                  # Camera feature
│   │   ├── CameraManager.swift
│   │   ├── CameraPreview.swift
│   │   └── CameraView.swift
│   ├── Views/                   # SwiftUI screens
│   │   ├── PhotoReviewView.swift
│   │   ├── PhotoCard.swift
│   │   └── SettingsView.swift
│   ├── ViewModels/
│   │   └── FeedbackViewModel.swift
│   └── Services/                # Legacy services (being migrated)
│       ├── CoreDataStack.swift
│       ├── OpenAIService.swift
│       └── ServiceContainer.swift
│
└── PhotoCoachTests/             # Integration tests (~30s)
    ├── Tests/
    ├── Mocks/
    └── Helpers/
```

### Key Architectural Benefits

1. **Fast Testing**: Business logic tests run in 0.07s vs 2-5+ minutes
2. **Platform Abstraction**: Uses `PlatformImage` typealias for UIKit/AppKit compatibility  
3. **Dependency Injection**: `ServiceContainer` provides clean testing boundaries
4. **Protocol-Based Design**: All services implement testable protocols
5. **Modular Code**: Business logic separate from UI concerns

### Testing Strategy

#### Fast Unit Tests (PhotoCoachCore Package)
```bash
cd PhotoCoachCore && swift test
```
- **Execution Time**: ~0.07 seconds (100x faster than before)
- **No Simulator**: Pure Swift package tests
- **Real Logic**: Tests actual KeychainService, PhotoStorageService, etc.
- **Coverage**: Protocol conformance, business logic, error handling

#### Integration Tests (Xcode Target)
```bash
xcodebuild test -scheme PhotoCoach
```
- **Execution Time**: ~30 seconds (with simulator)
- **Full Stack**: Tests complete app integration
- **UI Testing**: Critical user flows only

This dual approach enables rapid TDD cycles while maintaining comprehensive coverage.

## Key Components

### Camera (UIKit Bridge)

The camera requires AVFoundation (UIKit), so we bridge it to SwiftUI:

| File | Purpose |
|------|---------|
| `CameraManager` | `@MainActor ObservableObject` that manages AVCaptureSession, handles permissions, captures photos. Tracks device orientation via `UIDevice` notifications and sets `videoRotationAngle` on capture for correct landscape/portrait photos. |
| `CameraPreview` | `UIViewRepresentable` that wraps AVCaptureVideoPreviewLayer for the live preview |
| `CameraView` | SwiftUI view with shutter button, last photo thumbnail, settings gear. UI locked to portrait, but photos capture in correct orientation based on device rotation. |

### Data Flow

```
Photo captured
     │
     ▼
PhotoStorage.savePhoto()     → Saves JPEG to Documents/Photos/
     │                       → Generates thumbnail
     ▼
CoreDataStack.createPhoto()  → Creates Photo entity with paths
     │
     ▼
CoreDataStack.createFeedback() → Creates empty AIFeedback entity
     │
     ▼
Navigate to PhotoReviewView
     │
     ▼
FeedbackViewModel.fetchFeedback()
     │
     ▼
OpenAIService.streamFeedback() → Sends image to GPT-4 Vision
     │                         → Streams response chunks
     ▼
FeedbackViewModel updates state → PhotoCard displays streaming text
     │
     ▼
CoreDataStack.updateFeedback() → Saves complete feedback
```

### Storage

| What | Where | How |
|------|-------|-----|
| Photo files | `Documents/Photos/*.jpg` | FileManager via PhotoStorage |
| Thumbnails | `Documents/Thumbnails/*_thumb.jpg` | FileManager via PhotoStorage |
| Metadata | Core Data | Photo & AIFeedback entities |
| API Key | Keychain | KeychainHelper (Security framework) |

### AI Integration

`OpenAIService` (singleton) uses the OpenAI Responses API with session continuity:

1. Image resized to max 1024px and converted to base64
2. POST to `/v1/responses` with `stream: true` and `store: true`
3. On subsequent photos, `previous_response_id` chains to prior response (OpenAI remembers context server-side)
4. Parse SSE chunks, yield text via `AsyncThrowingStream`
5. `FeedbackViewModel` accumulates chunks and updates `@Published` state
6. SwiftUI automatically re-renders as text streams in

This allows the AI coach to reference patterns across multiple photos in a session without re-sending previous images.

### Error Handling

- **No API key** → Error state with "go to settings" prompt
- **Network failure** → Retry button on PhotoCard
- **Camera denied** → Permission denied view with "Open Settings" button

## Previews

All views have `#Preview` blocks for Xcode Canvas:
- `SettingsView` - Works fully
- `PhotoReviewView` - Shows empty state
- `PhotoCard` - Shows with mock photo
- `CameraView` - Shows permission denied state (no camera in simulator)
