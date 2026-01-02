# PhotoCoach - Deferred Features

## Camera Features (Post-MVP)
- **Front/back camera toggle** - Support selfie mode
- **Flash control** - On/off/auto modes

## Onboarding & UX
- **First-launch onboarding flow** - Guide users through API key setup on first open
- **Auto-retry with exponential backoff** - Automatically retry failed AI requests
- **Offline queue** - Queue photos for AI processing when network is unavailable

## Coaching Features
- **Update prompt for reshoot suggestions** - Spatial/positional guidance ("step 2 feet left", "lower your angle") with photography principle explanations (leading lines, fill the frame, light direction) to build skill over time
- **"Try Again" mode** - After feedback, reshoot button that keeps previous photo context, overlays the suggestion on camera, and compares before/after
- **Daily challenges** - Themed assignments ("Find leading lines"), specific skill focus with examples, end-of-day review
- **In-depth reviews** - Substantially increase tokens in LLM output and reframe the prompt to give more thorough feedback. Example prompt: "You're a professional photographer helping teach a new photographer the craft. Analyze this photo and provide feedback. What's good about it? What could be improved?"
- **Single-photo detail view** - After taking a photo, jump to a dedicated view showing the full in-depth analysis with a text box for followup questions. The scrollable gallery (accessed via button) shows only summaries.
- **Sessions** - Introduce sessions to keep context windows smaller. User can enter a focus for the session (e.g., a concept they're working on or an idea they want to convey), which gets fed into the feedback prompt either at session start or with each photo.

## Future Considerations
- **Backend proxy for AI** - Better API key security and usage controls
- **Photo editing** - Basic adjustments before AI review
- **Sharing capabilities** - Export photos with feedback
- **History/favorites** - Mark and find best photos
- **Different coaching modes** - Portrait, landscape, etc.
- **Offline mode** - Cache feedback for viewing without internet