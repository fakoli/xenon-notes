//
//  ContentView.swift
//  xenon-notes
//
//  Created by Sekou Doumbouya on 7/7/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recording.createdAt, order: .reverse) private var recordings: [Recording]
    @State private var selectedRecording: Recording?
    @State private var audioService = AudioRecordingService()
    @State private var isRecording = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingSettings = false
    @State private var appSettings: AppSettings?
    @State private var showOnboarding = false
    @State private var hasCheckedOnboarding = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.001)
                .ignoresSafeArea()
            
            // Main content
            NavigationStack {
                VStack(spacing: 0) {
                    // Top ornament navigation
                    NavigationOrnament(
                        showingSettings: $showingSettings,
                        isRecording: $isRecording,
                        appSettings: appSettings,
                        onNewRecording: {
                            if !isRecording {
                                startRecording()
                            } else {
                                stopRecording()
                            }
                        }
                    )
                    .padding(.top, 20)
                    .padding(.horizontal)
                    .offset(z: 150)
                
                    // Recording Controls (if actively recording)
                    if isRecording {
                        RecordingControlsView(
                            isRecording: $isRecording,
                            recordingTime: audioService.recordingTime,
                            audioLevel: audioService.audioLevel,
                            currentTranscript: audioService.currentTranscript,
                            onStartRecording: startRecording,
                            onStopRecording: stopRecording
                        )
                        .padding()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .offset(z: 200)
                    }
                    
                    // Main Content
                    ScrollView {
                        if recordings.isEmpty && !isRecording {
                        VStack(spacing: 20) {
                            Model3D(named: "Scene", bundle: realityKitContentBundle)
                                .padding(.bottom, 30)
                                .opacity(isRecording ? 0.5 : 1.0)
                            
                            Text("Welcome to Xenon Notes")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(.white)
                                .opacity(isRecording ? 0.5 : 1.0)
                            
                            Text("Your AI-powered voice recording assistant")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.65))
                                .opacity(isRecording ? 0.5 : 1.0)
                            
                            ToggleImmersiveSpaceButton()
                                .padding(.top)
                                .scaleEffect(1.2)
                        }
                        .padding()
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recordings")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                
                                LazyVStack(spacing: 16) {
                                    ForEach(recordings) { recording in
                                        RecordingRow(recording: recording)
                                            .onTapGesture {
                                                if !isRecording {
                                                    selectedRecording = recording
                                                }
                                            }
                                            .opacity(isRecording ? 0.5 : 1.0)
                                            .allowsHitTesting(!isRecording)
                                            .transition(.asymmetric(
                                                insertion: .scale.combined(with: .opacity),
                                                removal: .scale.combined(with: .opacity)
                                            ))
                                    }
                                    .onDelete(perform: deleteRecordings)
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.top, 20)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
                .navigationTitle("")
                .navigationBarHidden(true)
            }
            .offset(z: 0)
            
            // Floating title at top
            VStack {
                Text("Xenon Notes")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.8), Color.black.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)
                        .ignoresSafeArea()
                    )
                
                Spacer()
            }
            .allowsHitTesting(false)
            .offset(z: -50)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedRecording) { recording in
            RecordingDetailView(recording: recording)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("Recording Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            audioService.setModelContext(modelContext)
            loadSettings()
            checkOnboarding()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .onDisappear {
                    // Reload settings after onboarding
                    loadSettings()
                }
        }
        .onChange(of: showingSettings) { _, isShowing in
            if !isShowing {
                // Reload settings when settings view is dismissed
                loadSettings()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isRecording)
    }
    
    private func deleteRecordings(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(recordings[index])
        }
    }
    
    private func startRecording() {
        Task {
            do {
                // Enable Deepgram if configured
                if appSettings?.deepgramEnabled == true {
                    await setupDeepgram()
                }
                
                try await audioService.startRecording()
                isRecording = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func stopRecording() {
        Task {
            await audioService.stopRecording()
            isRecording = false
            
            // Force a save to ensure the recording appears immediately
            try? modelContext.save()
        }
    }
    
    private func loadSettings() {
        appSettings = AppSettings.loadOrCreate(in: modelContext)
    }
    
    private func checkOnboarding() {
        guard !hasCheckedOnboarding else { return }
        hasCheckedOnboarding = true
        
        // Check if user has any API keys configured
        Task {
            var hasAnyKey = false
            
            // Check for Deepgram key
            if let _ = try? KeychainService.retrieveAPIKey(for: .deepgram) {
                hasAnyKey = true
            }
            
            // Check for any profile with API key
            for profile in recordings.compactMap({ $0.processingProfile }) {
                if let _ = try? KeychainService.retrieveProfileAPIKey(
                    profileID: profile.apiKeyIdentifier,
                    service: profile.llmService
                ) {
                    hasAnyKey = true
                    break
                }
            }
            
            await MainActor.run {
                if !hasAnyKey && recordings.isEmpty {
                    showOnboarding = true
                }
            }
        }
    }
    
    private func setupDeepgram() async {
        do {
            if let apiKey = try KeychainService.retrieveAPIKey(for: .deepgram) {
                try await audioService.enableDeepgram(apiKey: apiKey)
            } else {
                print("No Deepgram API key found in Keychain")
            }
        } catch KeychainService.KeychainError.retrieveFailed(let status) where status == -25303 {
            // Item not found - this is expected if no key has been saved yet
            print("No Deepgram API key saved yet")
        } catch {
            print("Failed to setup Deepgram: \(error)")
        }
    }
}

struct RecordingRow: View {
    let recording: Recording
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDuration(recording.duration))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    
                    if recording.transcript != nil {
                        Label("Transcribed", systemImage: "text.quote")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.green)
                    }
                }
            }
            
            if let transcript = recording.transcript {
                Text(transcript.rawText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(.regularMaterial.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .hoverEffect(.automatic)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        TimeFormatter.durationString(from: duration)
    }
}

struct RecordingDetailView: View {
    let recording: Recording
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showProcessingSheet = false
    @State private var isRetranscribing = false
    @State private var retranscribeError: String?
    @State private var showRetranscribeError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Recording info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recording.title)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                        
                        HStack {
                            Label(recording.createdAt.formatted(date: .complete, time: .shortened), systemImage: "calendar")
                            
                            Spacer()
                            
                            Label(formatDuration(recording.duration), systemImage: "timer")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    
                    // Transcript
                    if let transcript = recording.transcript {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Transcript")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                // Only show retranscribe if we have audio chunks
                                if !recording.chunks.isEmpty {
                                    Button("Retranscribe") {
                                        retranscribe()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .disabled(isRetranscribing)
                                }
                            }
                            
                            if isRetranscribing {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Retranscribing...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            
                            Text(transcript.rawText)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white)
                                .textSelection(.enabled)
                        }
                        .padding()
                        .background(.regularMaterial.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    } else if !recording.chunks.isEmpty {
                        // Show retranscribe button if no transcript but have chunks
                        VStack(spacing: 12) {
                            Text("No transcript available")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Button("Transcribe Recording") {
                                retranscribe()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isRetranscribing)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    // Process with AI button
                    if recording.transcript != nil {
                        Button("Process with AI") {
                            showProcessingSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .padding(.horizontal)
                        .hoverEffect(.automatic)
                    }
                    
                    // Processed Results
                    if !recording.processedResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Processing Results")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            ForEach(recording.processedResults.sorted(by: { $0.createdAt > $1.createdAt })) { result in
                                ProcessedResultCard(result: result)
                            }
                        }
                        .padding()
                        .background(.regularMaterial.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    // Chunks info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Audio Chunks")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        ForEach(recording.chunks.sorted(by: { $0.index < $1.index })) { chunk in
                            HStack {
                                Text("Chunk \(chunk.index + 1)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Text(chunk.status.rawValue.capitalized)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(backgroundForStatus(chunk.status))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showProcessingSheet) {
            ProcessingProfileSelectionView(recording: recording)
        }
        .alert("Retranscription Error", isPresented: $showRetranscribeError) {
            Button("OK") {
                showRetranscribeError = false
            }
        } message: {
            Text(retranscribeError ?? "Unknown error occurred")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        TimeFormatter.durationString(from: duration)
    }
    
    private func backgroundForStatus(_ status: ChunkStatus) -> Color {
        switch status {
        case .completed:
            return .green.opacity(0.2)
        case .failed:
            return .red.opacity(0.2)
        case .transcribing:
            return .blue.opacity(0.2)
        default:
            return .gray.opacity(0.2)
        }
    }
    
    private func retranscribe() {
        guard !recording.chunks.isEmpty else { 
            retranscribeError = "No audio chunks found"
            showRetranscribeError = true
            return 
        }
        
        // Check if audio files exist
        var hasAudioFiles = false
        for chunk in recording.chunks {
            if let url = chunk.fileURL, FileManager.default.fileExists(atPath: url.path) {
                hasAudioFiles = true
                break
            }
        }
        
        if !hasAudioFiles {
            retranscribeError = "Audio files not found. The recording may have been made without saving audio data."
            showRetranscribeError = true
            return
        }
        
        isRetranscribing = true
        retranscribeError = nil
        
        // For now, show a message that this feature is coming soon
        // TODO: Implement proper audio file transcription using Deepgram's file API
        Task {
            await MainActor.run {
                retranscribeError = "Retranscription from audio files is coming soon. Currently, transcription only works during live recording."
                showRetranscribeError = true
                isRetranscribing = false
            }
        }
    }
}

enum RetranscribeError: LocalizedError {
    case missingAPIKey
    case noChunks
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Deepgram API key not found. Please configure it in Settings."
        case .noChunks:
            return "No audio chunks found for this recording."
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
        .modelContainer(for: [Recording.self, AudioChunk.self])
}
