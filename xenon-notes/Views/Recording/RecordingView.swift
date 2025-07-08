//
//  RecordingView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import SwiftData

struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var audioService = AudioRecordingService()
    @State private var isRecording = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showTranscript = false
    
    var body: some View {
        ZStack {
            // Background layer
            Color.black.opacity(0.001)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 40) {
                // Header with glass material
                HStack {
                    Button(action: {
                        Task {
                            if isRecording {
                                await audioService.stopRecording()
                            }
                            dismiss()
                        }
                    }) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 44)
                    }
                    .frame(width: 80, height: 60)
                    .background(.regularMaterial.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .hoverEffect(.automatic)
                    
                    Spacer()
                    
                    Text("New Recording")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            if isRecording {
                                await audioService.stopRecording()
                            }
                            dismiss()
                        }
                    }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 44)
                    }
                    .frame(width: 80, height: 60)
                    .background(.regularMaterial.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .hoverEffect(.automatic)
                    .disabled(audioService.recordingTime == 0)
                    .opacity(audioService.recordingTime == 0 ? 0.5 : 1.0)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            
                Spacer()
                
                // Central recording display
                VStack(spacing: 24) {
                    // Time display with depth
                    Text(timeString(from: audioService.recordingTime))
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.regularMaterial.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                        .offset(z: 50)
            
                    // Audio visualization with glass background
                    VStack(spacing: 16) {
                        AudioLevelView(level: audioService.audioLevel, height: 80)
                            .padding(.horizontal)
                        
                        if isRecording {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .fill(.red)
                                            .frame(width: 12, height: 12)
                                            .opacity(0.3)
                                            .scaleEffect(2.5)
                                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isRecording)
                                    )
                                
                                Text("Recording")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(maxWidth: 600)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial.opacity(0.4))
                    )
                    .padding(.horizontal, 40)
            
                    // Live transcript preview (if enabled)
                    if !audioService.currentTranscript.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Live Transcript")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.65))
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        showTranscript.toggle()
                                    }
                                }) {
                                    Image(systemName: showTranscript ? "chevron.up.circle" : "chevron.down.circle")
                                        .font(.title3)
                                        .foregroundStyle(.white.opacity(0.65))
                                }
                            }
                            
                            if showTranscript {
                                ScrollView {
                                    Text(audioService.currentTranscript)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxHeight: 120)
                                .transition(.asymmetric(
                                    insertion: .push(from: .top).combined(with: .opacity),
                                    removal: .push(from: .bottom).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding()
                        .frame(maxWidth: 600)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.regularMaterial.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            
                Spacer()
                
                // Record button with spatial positioning
                RecordButton(isRecording: $isRecording) {
                    Task {
                        if isRecording {
                            await audioService.stopRecording()
                            isRecording = false
                        } else {
                            do {
                                audioService.setModelContext(modelContext)
                                try await audioService.startRecording()
                                isRecording = true
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showTranscript = true
                                }
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                }
                .scaleEffect(1.2)
                .offset(z: 100)
                .padding(.bottom, 40)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRecording)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showTranscript)
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.black.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .alert("Recording Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            audioService.setModelContext(modelContext)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let tenths = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}



#Preview {
    RecordingView()
        .modelContainer(for: [Recording.self, AudioChunk.self])
}
