# Xenon Notes

**AI-Powered Voice Recording for Apple Vision Pro**

Xenon Notes is a mixed-reality application that transforms how you capture and process voice recordings. Record conversations, get real-time transcriptions, and leverage AI to summarize, analyze, or transform your notes into any format you need.

![visionOS](https://img.shields.io/badge/visionOS-2.0+-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Features

### Voice Recording
- **High-quality audio capture** with configurable recording quality (22kHz, 44kHz, 48kHz)
- **Real-time audio level visualization** with color-coded waveform display
- **Automatic chunking** into 30-second segments for efficient processing
- **Seamless recording flow** integrated directly into the main interface

### Live Transcription
- **Real-time speech-to-text** powered by Deepgram's Nova-2 model
- **WebSocket streaming** for instant transcript updates while recording
- **Word-level timing** and confidence scores
- **Multi-language support** with configurable language settings

### AI Processing
- **Multiple LLM providers**: OpenAI (GPT-4o), Anthropic (Claude), Google Gemini
- **Custom processing profiles** with personalized system prompts
- **Configurable model parameters**: temperature, max tokens, top-p
- **Per-profile API keys** for team or multi-account setups

### Spatial Interface
- **Glass design system** following Apple's visionOS design principles
- **Floating navigation ornament** for spatial interaction
- **Immersive 3D space** with RealityKit integration
- **Responsive hover effects** and spring animations

---

## Screenshots

*Coming soon: Screenshots of the recording interface, transcription view, and immersive space.*

---

## Requirements

- **Hardware**: Apple Vision Pro
- **Software**: visionOS 2.0 or later
- **Development**: Xcode 16+, macOS 15+

### API Keys Required
- [Deepgram](https://deepgram.com) - Speech-to-text transcription
- [OpenAI](https://platform.openai.com) - GPT models (optional)
- [Anthropic](https://anthropic.com) - Claude models (optional)
- [Google AI Studio](https://aistudio.google.com) - Gemini models (optional)

---

## Installation

### Clone the Repository

```bash
git clone https://github.com/fakoli/xenon-notes.git
cd xenon-notes
```

### Open in Xcode

```bash
open xenon-notes.xcodeproj
```

### Build and Run

1. Select the **xenon-notes** scheme
2. Choose **Apple Vision Pro** simulator as the destination
3. Press **Cmd+R** to build and run

### Configure API Keys

1. Launch the app in the simulator
2. Open **Settings** via the navigation ornament
3. Navigate to **API Keys**
4. Enter your API keys for each service you want to use

---

## Project Structure

```
xenon-notes/
├── xenon-notes/
│   ├── Models/                 # SwiftData entities
│   │   ├── Recording.swift     # Voice recording model
│   │   ├── AudioChunk.swift    # Audio segment model
│   │   ├── Transcript.swift    # Transcription model
│   │   ├── Profile.swift       # AI processing profile
│   │   ├── ProcessedResult.swift
│   │   └── AppSettings.swift
│   ├── Views/
│   │   ├── ContentView.swift   # Main 2D window
│   │   ├── ImmersiveView.swift # 3D immersive space
│   │   ├── Components/         # Reusable UI components
│   │   ├── Recording/          # Recording interface
│   │   └── Settings/           # Configuration views
│   ├── Services/
│   │   ├── AudioRecordingService.swift
│   │   ├── DeepgramService.swift
│   │   ├── AnthropicService.swift
│   │   ├── OpenAIService.swift
│   │   └── KeychainService.swift
│   ├── Theme/
│   │   ├── GlassTheme.swift    # Design tokens
│   │   └── SpatialLayout.swift # Spatial positioning
│   └── Utilities/
├── Packages/
│   └── RealityKitContent/      # 3D assets
└── xenon-notesTests/           # Unit tests
```

---

## Architecture

### Data Layer
Xenon Notes uses **SwiftData** for persistence with the following entity relationships:

```
Recording (1) ──┬── (N) AudioChunk
                ├── (1) Transcript ── (N) TranscriptSegment
                └── (N) ProcessedResult ── (1) Profile
```

### Service Layer
- **AudioRecordingService**: Manages AVAudioEngine, microphone capture, and chunking
- **DeepgramService**: Handles WebSocket connection for real-time STT
- **LLM Services**: Factory pattern for OpenAI, Anthropic, and Gemini integrations
- **KeychainService**: Secure credential storage

### UI Layer
- **Glass Design System**: Consistent vibrancy, typography, and spacing
- **Spatial Navigation**: Floating ornament with expandable sections
- **Component Library**: Reusable glass cards, badges, and buttons

For detailed architecture documentation, see [ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Usage

### Recording a Note

1. Tap the **microphone button** in the navigation ornament or main view
2. Speak your note while watching the real-time waveform
3. View the **live transcript** as Deepgram processes your speech
4. Tap **Stop** to save the recording

### Processing with AI

1. Select a recording from your library
2. Tap **Process with AI**
3. Choose a processing profile (e.g., "Summarize", "Action Items")
4. View the AI-generated result

### Creating Custom Profiles

1. Open **Settings > AI Profiles**
2. Tap **Add Profile**
3. Configure:
   - Name and icon
   - LLM provider and model
   - System prompt
   - Model parameters
4. Save and use your custom profile

---

## Development

### Building

```bash
# Debug build
xcodebuild -scheme xenon-notes -configuration Debug build

# Run tests
device='platform=visionOS Simulator,name=Apple Vision Pro'
xcodebuild test -scheme xenon-notes -destination "$device"
```

### 3D Assets

1. Open Reality Composer Pro:
   ```
   Packages/RealityKitContent/Package.realitycomposerpro
   ```
2. Edit USDZ/USDA assets
3. Assets auto-bundle via Swift Package build

### Adding a New LLM Provider

1. Create a new service implementing `LLMServiceProtocol`
2. Add the provider to the `LLMService` enum in `Profile.swift`
3. Register in `LLMServiceFactory`
4. Add API key field in `APIKeysView`

---

## Design System

### Glass Theme

| Token              | Value                          |
| ------------------ | ------------------------------ |
| Primary vibrancy   | 1.0 opacity                    |
| Secondary vibrancy | 0.65 opacity                   |
| Tertiary vibrancy  | 0.35 opacity                   |
| Minimum tap target | 60 x 60 pt                     |
| Animation spring   | response 0.3, damping 0.8      |

### Typography

| Style              | Size | Weight |
| ------------------ | ---- | ------ |
| Extra Large Title  | 48pt | Bold   |
| Large Title        | 34pt | Bold   |
| Title              | 28pt | Bold   |
| Body               | 17pt | Medium |
| Caption            | 12pt | Medium |

---

## Roadmap

- [ ] File-based retranscription via Deepgram REST API
- [ ] Google Gemini integration
- [ ] Export recordings (audio + transcript)
- [ ] Share processed results
- [ ] Enhanced spatial widgets
- [ ] Persistent UI position memory
- [ ] iCloud sync

---

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

### Quick Start

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes following the coding conventions
4. Write tests for new functionality
5. Submit a pull request

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Deepgram](https://deepgram.com) for speech-to-text API
- [OpenAI](https://openai.com) for GPT models
- [Anthropic](https://anthropic.com) for Claude models
- Apple for visionOS and the spatial computing platform

---

## Support

- **Issues**: [GitHub Issues](https://github.com/fakoli/xenon-notes/issues)
- **Discussions**: [GitHub Discussions](https://github.com/fakoli/xenon-notes/discussions)

---

*Built with Swift and SwiftUI for Apple Vision Pro*
