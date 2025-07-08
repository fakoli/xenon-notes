//
//  TranscriptionTestView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import AVFoundation

struct TranscriptionTestView: View {
    let apiKey: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var audioService = AudioRecordingService()
    @State private var isRecording = false
    @State private var transcript = ""
    @State private var error: String?
    @State private var recordingTime: TimeInterval = 0
    @State private var timerTask: Task<Void, Never>?
    @State private var hasStarted = false
    
    private let testDuration: TimeInterval = 10.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: isRecording ? "mic.circle.fill" : "mic.circle")
                        .font(.system(size: 80))
                        .foregroundStyle(isRecording ? .red : .blue)
                        .symbolEffect(.variableColor.iterative, isActive: isRecording)
                    
                    if isRecording {
                        Text("Recording...")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Timer
                        Text(String(format: "%.1f / %.0f seconds", recordingTime, testDuration))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        // Progress
                        ProgressView(value: recordingTime, total: testDuration)
                            .progressViewStyle(.linear)
                            .padding(.horizontal)
                    } else if hasStarted {
                        Text("Test Complete")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    } else {
                        Text("Ready to Test")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                // Instructions
                if !hasStarted {
                    VStack(spacing: 12) {
                        Text("This test will:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Record 10 seconds of audio", systemImage: "mic")
                            Label("Send it to Deepgram", systemImage: "network")
                            Label("Show the transcription result", systemImage: "text.quote")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Transcript Result
                if !transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Transcription Result")
                                .font(.headline)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        
                        ScrollView {
                            Text(transcript)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .frame(maxHeight: 150)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                }
                
                // Error
                if let error = error {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error")
                            .font(.headline)
                            .foregroundStyle(.red)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Control Button
                if isRecording {
                    Button("Stop Test") {
                        stopRecording()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    Button(hasStarted ? "Test Again" : "Start Test") {
                        startRecording()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isRecording)
                }
            }
            .padding()
            .navigationTitle("Transcription Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        if isRecording {
                            stopRecording()
                        }
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupAudioService()
        }
        .onDisappear {
            if isRecording {
                stopRecording()
            }
        }
        .onChange(of: audioService.currentTranscript) { _, newValue in
            if !newValue.isEmpty {
                transcript = newValue
            }
        }
    }
    
    private func setupAudioService() {
        Task {
            do {
                try await audioService.enableDeepgram(apiKey: apiKey)
            } catch {
                self.error = "Failed to setup Deepgram: \(error.localizedDescription)"
            }
        }
    }
    
    private func startRecording() {
        hasStarted = true
        transcript = ""
        error = nil
        recordingTime = 0
        
        Task {
            do {
                try await audioService.startRecording()
                isRecording = true
                
                // Start timer
                timerTask = Task {
                    while !Task.isCancelled && recordingTime < testDuration {
                        try? await Task.sleep(for: .milliseconds(100))
                        await MainActor.run {
                            recordingTime += 0.1
                            
                            // Auto-stop at test duration
                            if recordingTime >= testDuration {
                                stopRecording()
                            }
                        }
                    }
                }
            } catch {
                self.error = error.localizedDescription
                isRecording = false
            }
        }
    }
    
    private func stopRecording() {
        timerTask?.cancel()
        timerTask = nil
        
        Task {
            await audioService.stopRecording()
            isRecording = false
            
            // Get final transcript
            if let deepgramService = audioService.deepgramService {
                transcript = deepgramService.finalTranscript
            }
            
            if transcript.isEmpty {
                transcript = "No transcription received. Please check your API key and connection."
            }
        }
    }
}


