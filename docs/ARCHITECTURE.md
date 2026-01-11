# Architecture Overview

This document describes the technical architecture of Xenon Notes, a mixed-reality voice recording application for Apple Vision Pro.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Data Layer](#data-layer)
3. [Service Layer](#service-layer)
4. [UI Layer](#ui-layer)
5. [State Management](#state-management)
6. [Data Flow](#data-flow)
7. [External Integrations](#external-integrations)
8. [Security](#security)

---

## System Overview

Xenon Notes follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ ContentView │  │ImmersiveView│  │   Settings Views    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                     Service Layer                           │
│  ┌───────────────────┐  ┌───────────────┐  ┌─────────────┐  │
│  │AudioRecordingServ.│  │DeepgramService│  │ LLM Services│  │
│  └───────────────────┘  └───────────────┘  └─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  SwiftData  │  │  Keychain   │  │    File System      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Layer

### SwiftData Models

The app uses SwiftData for persistent storage with the following entity relationships:

```
Recording
├── id: UUID
├── title: String
├── createdAt: Date
├── duration: TimeInterval
├── audioFileURL: URL?
├── chunks: [AudioChunk]        ─── cascade delete
├── transcript: Transcript?      ─── cascade delete
├── processingProfile: Profile?
└── processedResults: [ProcessedResult]  ─── cascade delete

AudioChunk
├── id: UUID
├── index: Int                   # Order in recording (0, 1, 2...)
├── startTime: TimeInterval
├── duration: TimeInterval
├── fileURL: URL?
├── status: ChunkStatus          # recording | queued | transcribing | completed | failed
├── recording: Recording?
└── transcriptSegment: TranscriptSegment?

Transcript
├── id: UUID
├── rawText: String
├── processedText: String?
├── language: String             # Default: "en"
├── createdAt: Date
├── updatedAt: Date
├── recording: Recording?
└── segments: [TranscriptSegment]  ─── cascade delete

TranscriptSegment
├── id: UUID
├── text: String
├── startTime: TimeInterval
├── endTime: TimeInterval
├── confidence: Double           # 0.0 - 1.0
├── transcript: Transcript?
└── audioChunk: AudioChunk?

Profile
├── id: UUID
├── name: String
├── icon: String                 # SF Symbol name
├── llmService: LLMService       # openai | anthropic | gemini | custom
├── modelName: String
├── apiKeyIdentifier: String?
├── systemPrompt: String
├── temperature: Double
├── maxTokens: Int
├── topP: Double
├── frequencyPenalty: Double
├── presencePenalty: Double
├── isActive: Bool
├── createdAt: Date
├── recordings: [Recording]
└── processedResults: [ProcessedResult]

ProcessedResult
├── id: UUID
├── createdAt: Date
├── processedText: String
├── prompt: String
├── modelUsed: String
├── temperature: Double
├── maxTokens: Int
├── processingTime: TimeInterval
├── recording: Recording?
└── profile: Profile?

AppSettings (Singleton)
├── id: UUID
├── deepgramEnabled: Bool
├── deepgramModel: String        # Default: "nova-2"
├── deepgramLanguage: String     # Default: "en"
├── autoProcessTranscripts: Bool
├── processOnRecordingEnd: Bool
├── showTranscriptWhileRecording: Bool
├── recordingQuality: RecordingQuality  # low | medium | high
└── hasCompletedOnboarding: Bool
```

### Model Container Setup

```swift
// In xenon_notesApp.swift
@main
struct xenon_notesApp: App {
    var modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Recording.self,
            AudioChunk.self,
            Transcript.self,
            TranscriptSegment.self,
            Profile.self,
            AppSettings.self,
            ProcessedResult.self
        ])
        do {
            modelContainer = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
```

---

## Service Layer

### AudioRecordingService

Manages audio capture and recording lifecycle.

**Responsibilities:**
- AVAudioEngine setup and microphone permissions
- Real-time audio level metering
- 30-second chunk segmentation
- File system management for audio files
- Integration with DeepgramService for live transcription

**Key Properties:**
```swift
@Observable class AudioRecordingService {
    var isRecording: Bool
    var audioLevel: Float           // 0.0 - 1.0
    var recordingTime: TimeInterval
    var currentTranscript: String
    var currentRecording: Recording?
}
```

**Recording Flow:**
1. Request microphone permission
2. Initialize AVAudioEngine with input node
3. Install tap for audio buffer processing
4. Start chunk timer (30-second intervals)
5. Stream audio to DeepgramService if enabled
6. Update audio level for visualization
7. On stop: finalize chunks, save to SwiftData

### DeepgramService

Handles real-time speech-to-text via WebSocket.

**Configuration:**
```swift
struct DeepgramConfig {
    static let sampleRate = 16000
    static let channels = 1
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 300
}
```

**WebSocket Protocol:**
- Connects to `wss://api.deepgram.com/v1/listen`
- Streams raw audio bytes
- Receives JSON responses with transcript and metadata

**Response Handling:**
```swift
struct DeepgramResponse: Codable {
    let channel: Channel
    let isFinal: Bool

    struct Channel: Codable {
        let alternatives: [Alternative]
    }

    struct Alternative: Codable {
        let transcript: String
        let confidence: Double
        let words: [Word]?
    }
}
```

### LLM Services

Factory pattern for AI provider integrations.

**Protocol:**
```swift
protocol LLMServiceProtocol {
    func process(
        transcript: String,
        with profile: Profile,
        modelContext: ModelContext
    ) async throws -> ProcessedResult
}
```

**Implementations:**
- `AnthropicService`: Claude API via Messages endpoint
- `OpenAIService`: GPT API via Chat Completions endpoint
- `GeminiService`: Google AI API (planned)

**Factory:**
```swift
class LLMServiceFactory {
    static func service(for type: LLMService) -> LLMServiceProtocol {
        switch type {
        case .openai: return OpenAIService()
        case .anthropic: return AnthropicService()
        case .gemini: return GeminiService()
        case .custom: return CustomService()
        }
    }
}
```

### KeychainService

Secure storage for API credentials.

**Operations:**
```swift
class KeychainService {
    static func save(key: String, value: String) throws
    static func retrieve(key: String) -> String?
    static func delete(key: String) throws
}
```

**Key Identifiers:**
- `deepgram_api_key`
- `openai_api_key`
- `anthropic_api_key`
- `gemini_api_key`
- `profile_{uuid}_api_key` (per-profile keys)

---

## UI Layer

### View Hierarchy

```
xenon_notesApp
├── ContentView (WindowGroup)
│   ├── NavigationOrnament
│   │   ├── Recording Section
│   │   ├── Library Section
│   │   └── Tools Section
│   ├── Recording List
│   │   └── Recording Rows
│   ├── RecordingControlsView (when recording)
│   │   ├── Timer Display
│   │   ├── AudioLevelView
│   │   └── Transcript Preview
│   ├── Recording Detail Sheet
│   │   ├── Transcript View
│   │   └── ProcessedResults
│   └── Settings Sheet
│       ├── DeepgramSettingsView
│       ├── ProfileManagementView
│       ├── APIKeysView
│       └── GeneralSettingsView
└── ImmersiveView (ImmersiveSpace)
    └── RealityKit Content
```

### Design System

**GlassTheme.swift:**
```swift
enum GlassTheme {
    enum Vibrancy {
        case primary    // 1.0 opacity
        case secondary  // 0.65 opacity
        case tertiary   // 0.35 opacity
    }

    enum Spacing {
        static let minimum: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    static let minimumTapTarget = CGSize(width: 60, height: 60)
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.8)
}
```

### Component Library

| Component                    | Purpose                              |
| ---------------------------- | ------------------------------------ |
| `GlassCard`                  | Container with glass material        |
| `GlassStatusBadge`           | Status indicator                     |
| `NavigationOrnament`         | Floating navigation panel            |
| `AudioLevelView`             | Waveform visualization               |
| `RecordButton`               | Main recording trigger               |
| `ProcessingProfileSelection` | AI profile picker grid               |
| `FloatingActionButton`       | Prominent action button              |

---

## State Management

### AppModel

Global application state using the `@Observable` macro:

```swift
@Observable class AppModel {
    var immersiveSpaceState: ImmersiveSpaceState = .closed
    var isShowingImmersiveSpace: Bool = false

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
}
```

### View State

Local view state managed with `@State`:
- `isRecording`: Recording session active
- `selectedRecording`: Currently viewed recording
- `showingSettings`: Settings sheet visible
- `showOnboarding`: First-launch flow

### Environment Injection

```swift
ContentView()
    .environment(appModel)
    .modelContainer(modelContainer)
```

---

## Data Flow

### Recording Flow

```
User taps Record
       │
       ▼
┌──────────────────┐
│ Request Mic      │
│ Permission       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│ Start            │────▶│ Connect to       │
│ AVAudioEngine    │     │ Deepgram WS      │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         ▼                        ▼
┌──────────────────┐     ┌──────────────────┐
│ Create Recording │     │ Stream Audio     │
│ in SwiftData     │     │ Buffers          │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         ▼                        ▼
┌──────────────────┐     ┌──────────────────┐
│ Chunk Timer      │     │ Receive          │
│ (30s intervals)  │     │ Transcripts      │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         └────────────┬───────────┘
                      │
                      ▼
               User taps Stop
                      │
                      ▼
         ┌──────────────────┐
         │ Finalize Chunks  │
         │ Save Transcript  │
         └──────────────────┘
```

### AI Processing Flow

```
User selects transcript
         │
         ▼
┌──────────────────┐
│ Show Profile     │
│ Selection Grid   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ User selects     │
│ Profile          │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ LLMServiceFactory│
│ creates service  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Retrieve API key │
│ from Keychain    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Build request    │
│ with profile     │
│ parameters       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Send to LLM API  │
│ Measure time     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Create           │
│ ProcessedResult  │
│ in SwiftData     │
└──────────────────┘
```

---

## External Integrations

### Deepgram API

**Endpoint:** `wss://api.deepgram.com/v1/listen`

**Query Parameters:**
- `model=nova-2`
- `language=en`
- `encoding=linear16`
- `sample_rate=16000`
- `channels=1`

**Authentication:** `Authorization: Token {api_key}`

### OpenAI API

**Endpoint:** `https://api.openai.com/v1/chat/completions`

**Request:**
```json
{
  "model": "gpt-4o",
  "messages": [
    {"role": "system", "content": "{systemPrompt}"},
    {"role": "user", "content": "{transcript}"}
  ],
  "temperature": 0.7,
  "max_tokens": 2048
}
```

### Anthropic API

**Endpoint:** `https://api.anthropic.com/v1/messages`

**Headers:**
- `x-api-key: {api_key}`
- `anthropic-version: 2023-06-01` <!-- Verify this is the latest supported Anthropic API version and update as needed -->

**Request:**
```json
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 2048,
  "system": "{systemPrompt}",
  "messages": [
    {"role": "user", "content": "{transcript}"}
  ]
}
```

---

## Security

### API Key Storage

- All API keys stored in iOS Keychain (encrypted at rest)
- Keys retrieved only when needed for API calls
- Per-profile keys supported for team environments
- No keys stored in UserDefaults or files

### Audio Privacy

- Microphone access requires explicit permission
- Audio files stored in app sandbox
- Files cleaned up on recording deletion (cascade)

### Network Security

- All API communication over HTTPS/WSS
- No sensitive data in URL parameters
- Request timeouts to prevent hanging connections

---

## Performance Considerations

### Audio Buffering

- 30-second chunks balance memory usage and reliability
- Audio tap buffer size optimized for real-time processing
- Separate queue for audio processing to avoid UI blocking

### SwiftData Optimization

- Cascade delete relationships prevent orphaned data
- Lazy loading for transcript segments
- Batch operations for chunk creation

### UI Performance

- Spring animations for smooth interactions
- Lazy loading in recording list
- Minimal re-renders with `@Observable`

---

## Future Architecture Considerations

1. **Offline Mode**: Queue transcription requests when offline
2. **Background Processing**: Continue AI processing when app backgrounded
3. **iCloud Sync**: CloudKit integration for cross-device sync
4. **Streaming LLM**: Real-time AI responses during recording
5. **Plugin System**: Custom LLM provider registration

---

*Last updated: January 2026*
