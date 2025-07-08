//
//  RecordingControlsView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI

struct RecordingControlsView: View {
    @Binding var isRecording: Bool
    let recordingTime: TimeInterval
    let audioLevel: Float
    let currentTranscript: String
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isRecording {
                // Recording in progress
                VStack(spacing: 12) {
                    // Time display
                    Text(TimeFormatter.timeString(from: recordingTime))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundStyle(.primary)
                    
                    // Audio level
                    AudioLevelView(level: audioLevel, height: 40)
                        .padding(.horizontal)
                    
                    // Live transcript (if available and enabled)
                    if !currentTranscript.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Live Transcript")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            ScrollView {
                                Text(currentTranscript)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                            }
                            .frame(maxHeight: 100)
                        }
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    // Stop button
                    Button(action: onStopRecording) {
                        HStack {
                            Image(systemName: "stop.fill")
                                .font(.title3)
                            Text("Stop Recording")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(.red)
                        .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 20)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            } else {
                // Not recording
                Button(action: onStartRecording) {
                    HStack {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                        Text("Start Recording")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .clipShape(Capsule())
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .animation(.spring(response: 0.3), value: isRecording)
    }
}