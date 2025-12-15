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

```
PhotoCoach/
├── PhotoCoachApp.swift          # App entry point, injects CoreDataStack
├── AppDelegate.swift            # UIApplicationDelegate for orientation control
├── ContentView.swift            # Navigation container (NavigationStack)
│
├── Camera/                      # Camera feature
│   ├── CameraManager.swift      # AVFoundation logic (ObservableObject)
│   ├── CameraPreview.swift      # UIViewRepresentable bridge
│   └── CameraView.swift         # Camera UI (shutter, thumbnail, settings)
│
├── Views/                       # Main screens
│   ├── PhotoReviewView.swift    # Scrollable list of photos
│   ├── PhotoCard.swift          # Single photo + AI feedback display
│   └── SettingsView.swift       # API key management
│
├── ViewModels/
│   └── FeedbackViewModel.swift  # Manages streaming feedback state
│
├── Services/                    # Business logic
│   ├── CoreDataStack.swift      # Core Data setup + CRUD operations
│   ├── PhotoStorage.swift       # File system for images/thumbnails
│   ├── KeychainHelper.swift     # Secure API key storage
│   └── OpenAIService.swift      # GPT-4 Vision API client
│
├── Models/
│   └── PhotoCoach.xcdatamodeld  # Core Data model (Photo, AIFeedback)
│
└── Info.plist                   # Camera permission description
```

## Key Components

### Camera (UIKit Bridge)

The camera requires AVFoundation (UIKit), so we bridge it to SwiftUI:

| File | Purpose |
|------|---------|
| `CameraManager` | `@MainActor ObservableObject` that manages AVCaptureSession, handles permissions, captures photos |
| `CameraPreview` | `UIViewRepresentable` that wraps AVCaptureVideoPreviewLayer for the live preview |
| `CameraView` | SwiftUI view with shutter button, last photo thumbnail, settings gear. Locked to portrait orientation (like Apple Camera). |

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

`OpenAIService` sends images to GPT-4 Vision and streams the response:

1. Image resized to max 1024px and converted to base64
2. POST to `/v1/chat/completions` with `stream: true`
3. Parse SSE chunks, yield text via `AsyncThrowingStream`
4. `FeedbackViewModel` accumulates chunks and updates `@Published` state
5. SwiftUI automatically re-renders as text streams in

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
