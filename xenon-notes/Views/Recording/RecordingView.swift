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
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            HStack {
                Button("Cancel") {
                    Task {
                        if isRecording {
                            await audioService.stopRecording()
                        }
                        dismiss()
                    }
                }
                
                Spacer()
                
                Text("New Recording")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    Task {
                        if isRecording {
                            await audioService.stopRecording()
                        }
                        dismiss()
                    }
                }
                .disabled(audioService.recordingTime == 0)
            }
            .padding()
            
            Spacer()
            
            // Recording time display
            Text(timeString(from: audioService.recordingTime))
                .font(.system(size: 60, weight: .light, design: .monospaced))
                .foregroundStyle(.primary)
            
            // Audio level indicator
            AudioLevelView(level: audioService.audioLevel)
                .frame(height: 60)
                .padding(.horizontal, 40)
            
            // Recording status
            if isRecording {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                                .opacity(0.3)
                                .scaleEffect(2)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isRecording)
                        )
                    
                    Text("Recording...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Record button
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
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }
            .frame(width: 120, height: 120)
            
            Spacer()
        }
        .background(.regularMaterial)
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
