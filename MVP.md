# PhotoCoach MVP Plan

## Overview
AI-powered photo coaching app with two core screens: camera capture and photo review with AI feedback.

## Core Screens

### 1. Photo Capture Screen (Simplified)
**Goal**: Clean, minimal camera interface for capturing photos

**MVP Components**:
- **AVCaptureSession**: Back camera only, no flash
- **Minimal Camera View Controller**:
  - Live preview layer (AVCaptureVideoPreviewLayer)
  - Shutter button (large circular button at bottom center)
  - Last photo thumbnail (bottom-left corner, tappable to navigate to review)
  
**Technical Requirements**:
- Request camera permissions on first launch
- Fixed back camera configuration
- Basic orientation support
- Simple capture animation/feedback

### 2. Photo Review Screen
**Goal**: Display captured photos with streaming AI feedback

**MVP Components**:
- **Vertical Scroll View** (UITableView/UICollectionView):
  - Most recent photo at top
  - Each cell contains:
    - Photo (aspect-fit, full width)
    - AI feedback text area below photo
    - Timestamp
    - Loading indicator while AI processes

**AI Feedback Display**:
- Streaming text that appears progressively
- Simple text view with:
  - Composition feedback
  - Technical suggestions
  - Encouragement/tips
  
### 3. Data Model (Simplified)

```swift
Photo:
- id: UUID
- imageData: Data (stored as file)
- capturedAt: Date
- thumbnailData: Data

AIFeedback:
- id: UUID  
- photoId: UUID
- content: String
- isComplete: Bool
- createdAt: Date
```

**Storage**:
- Core Data for metadata
- Documents directory for photo files
- Simple thumbnail generation

### 4. AI Integration (MVP)

**Approach**: Direct OpenAI Vision API integration
- Settings screen for API key entry (stored in Keychain)
- Simple POST request with image
- Stream response handling
- Retry button on error (no auto-retry for MVP)

**AI Coach Persona**:
- Direct and technical feedback style
- Target audience: beginning phone photographers
- Focus areas (phone-relevant):
  - **Composition**: Rule of thirds, leading lines, framing, balance
  - **Lighting**: Direction, quality, shadows, highlights
  - **Subject**: Clarity, interest, placement, storytelling
- Explicitly NOT covering: focus, exposure settings, white balance (phone handles these automatically)

**API Flow**:
1. Capture photo → Save locally
2. Generate thumbnail → Update UI
3. Send to OpenAI Vision API
4. Stream response → Update feedback UI
5. Save complete feedback to Core Data

### 5. Navigation Flow

```
App Launch → Camera Screen
    ↓ (tap shutter)
    → Capture photo → Auto-navigate to Review
    ↓ (tap camera icon or swipe back)
    ← Return to Camera
```

### 6. Settings Screen (MVP)

**Components**:
- API Key input field (secure text entry)
- Save button
- Status indicator (valid/invalid/not set)

**Behavior**:
- Accessible from camera screen via gear icon
- API key stored securely in Keychain
- Basic validation (non-empty, starts with expected prefix)

### 7. MVP Technical Stack

- **UI**: SwiftUI with MVVM pattern
- **Camera**: AVFoundation (bridged via UIViewRepresentable)
- **Storage**: Core Data + FileManager
- **Networking**: URLSession with async/await streaming
- **Minimum iOS**: 26.1

## Success Criteria

1. Can capture a photo with one tap
2. Photo saves locally with thumbnail
3. AI feedback starts streaming within 2-3 seconds
4. Can view previous photos and their feedback
5. Smooth navigation between screens

## Out of Scope for MVP

See Followups.md for future enhancements.