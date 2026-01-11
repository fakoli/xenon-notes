# Contributing to Xenon Notes

Thank you for your interest in contributing to Xenon Notes! This document provides guidelines and instructions for contributing to the project.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Coding Standards](#coding-standards)
5. [Making Changes](#making-changes)
6. [Pull Request Process](#pull-request-process)
7. [Testing](#testing)
8. [Documentation](#documentation)

---

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment. Please be considerate in your interactions and focus on constructive collaboration.

---

## Getting Started

### Prerequisites

- **macOS 15** (Sequoia) or later
- **Xcode 16** or later
- **Apple Vision Pro Simulator** (included with Xcode)
- **Git** for version control

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:

```bash
git clone https://github.com/YOUR_USERNAME/xenon-notes.git
cd xenon-notes
```

3. Add the upstream remote:

```bash
git remote add upstream https://github.com/fakoli/xenon-notes.git
```

---

## Development Setup

### Opening the Project

```bash
open xenon-notes.xcodeproj
```

### Configuring API Keys (for Testing)

1. Launch the app in the simulator
2. Navigate to Settings > API Keys
3. Add test API keys for services you need to test

Alternatively, create a `.env` file (git-ignored):

```
DEEPGRAM_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
```

### Building

```bash
# Debug build
xcodebuild -scheme xenon-notes -configuration Debug build

# Release build
xcodebuild -scheme xenon-notes -configuration Release build
```

### Running Tests

```bash
device='platform=visionOS Simulator,name=Apple Vision Pro'
xcodebuild test -scheme xenon-notes -destination "$device"
```

---

## Coding Standards

### Swift Style Guide

We follow Swift's official API design guidelines and use swift-format for consistency.

#### Naming Conventions

- **Types**: PascalCase (`RecordingView`, `AudioChunk`)
- **Variables/Functions**: camelCase (`currentRecording`, `startRecording()`)
- **Constants**: camelCase (`defaultTimeout`)
- **Acronyms**: Treat as words (`apiKey`, `urlString`, `httpRequest`)

#### File Organization

```swift
// 1. Imports
import SwiftUI
import RealityKit

// 2. Type declaration
struct RecordingView: View {
    // 3. Properties (in order)
    // - Environment
    @Environment(\.modelContext) private var modelContext

    // - State
    @State private var isRecording = false

    // - Injected dependencies
    let audioService: AudioRecordingService

    // - Computed properties
    var formattedTime: String { ... }

    // 4. Body
    var body: some View { ... }

    // 5. Private methods
    private func startRecording() { ... }
}

// 6. Extensions
extension RecordingView {
    // Nested types, additional protocol conformances
}

// 7. Previews
#Preview {
    RecordingView(audioService: .preview)
}
```

#### Error Handling

Prefer `throws` with `do/catch` over optionals or `fatalError`:

```swift
// Preferred
func loadRecording() throws -> Recording {
    guard let data = try? Data(contentsOf: url) else {
        throw RecordingError.fileNotFound
    }
    return try decoder.decode(Recording.self, from: data)
}

// Avoid
func loadRecording() -> Recording? {
    // ...
}
```

#### Documentation

Add documentation for public APIs:

```swift
/// Processes a transcript using the specified AI profile.
/// - Parameters:
///   - transcript: The raw transcript text to process
///   - profile: The AI profile containing model settings
/// - Returns: A ProcessedResult with the AI response
/// - Throws: LLMError if the API request fails
func process(transcript: String, with profile: Profile) async throws -> ProcessedResult
```

---

## Making Changes

### Branching Strategy

This project uses a trunk-based development workflow with the following branch naming conventions:

1. **main**: Primary development and release branch - all PRs target this branch
2. **feature/***: New features (e.g., `feature/pause-recording`)
3. **fix/***: Bug fixes (e.g., `fix/websocket-reconnect`)
4. **docs/***: Documentation updates (e.g., `docs/api-guide`)

### Creating a Branch

```bash
# Sync with upstream
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name
```

### Commit Messages

Follow conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding missing tests
- `chore`: Maintenance tasks

**Examples:**

```
feat(recording): add pause functionality

- Added pause button to RecordingControlsView
- Implemented pause/resume in AudioRecordingService
- Updated recording state handling

Closes #42
```

```
fix(deepgram): handle WebSocket disconnection gracefully

Previously, an unexpected disconnect would crash the app.
Now we catch the error and attempt reconnection.
```

---

## Pull Request Process

### Before Submitting

1. **Sync with upstream**: Rebase on latest main
2. **Run tests**: Ensure all tests pass
3. **Build**: Verify clean build with no warnings
4. **Self-review**: Check your changes for issues

### Creating a Pull Request

1. Push your branch to your fork:

```bash
git push origin feature/your-feature-name
```

2. Open a PR on GitHub against the `main` branch

3. Fill out the PR template:

```markdown
## Summary
Brief description of changes

## Changes
- Change 1
- Change 2

## Testing
How to test these changes

## Screenshots
(if applicable)

## Checklist
- [ ] Tests pass
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] No new warnings
```

### Review Process

1. A maintainer will review your PR
2. Address any feedback with additional commits
3. Once approved, your PR will be merged
4. Delete your feature branch after merge

---

## Testing

### Unit Tests

Add tests for new functionality in `xenon-notesTests/`:

```swift
import XCTest
@testable import xenon_notes

final class AudioRecordingServiceTests: XCTestCase {
    var service: AudioRecordingService!

    override func setUp() {
        service = AudioRecordingService()
    }

    func testStartRecordingCreatesRecording() async throws {
        try await service.startRecording()
        XCTAssertNotNil(service.currentRecording)
    }

    func testAudioLevelUpdates() async throws {
        // Test audio level metering
    }
}
```

### Test Naming

Use descriptive names that explain what is being tested:

```swift
// Good
func testRecordingDurationUpdatesEverySecond()
func testDeepgramServiceReconnectsOnDisconnect()

// Avoid
func testRecording()
func testService()
```

### Running Specific Tests

```bash
# Run a specific test class
xcodebuild test -scheme xenon-notes \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  -only-testing:xenon-notesTests/AudioRecordingServiceTests

# Run a specific test method
xcodebuild test -scheme xenon-notes \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  -only-testing:xenon-notesTests/AudioRecordingServiceTests/testStartRecordingCreatesRecording
```

---

## Documentation

### When to Update Documentation

- Adding new features or APIs
- Changing existing behavior
- Fixing incorrect documentation
- Improving clarity

### Documentation Files

| File                    | Purpose                          |
| ----------------------- | -------------------------------- |
| `README.md`             | Project overview and setup       |
| `CLAUDE.md`             | AI assistant context             |
| `docs/ARCHITECTURE.md`  | Technical architecture           |
| `docs/CONTRIBUTING.md`  | Contribution guidelines          |

### Code Documentation

- Add inline comments for complex logic
- Use Swift documentation comments for public APIs
- Keep comments up to date with code changes

---

## Questions?

- **Issues**: Open a GitHub issue for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions

Thank you for contributing to Xenon Notes!
