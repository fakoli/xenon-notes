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
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    
                    // Audio level
                    AudioLevelView(level: audioLevel, height: 40)
                        .padding(.horizontal)
                    
                    // Live transcript (if available and enabled)
                    if !currentTranscript.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Live Transcript")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.65))
                                .padding(.horizontal)
                            
                            ScrollView {
                                Text(currentTranscript)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                            }
                            .frame(maxHeight: 100)
                        }
                        .background(.regularMaterial.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    // Stop button
                    Button(action: onStopRecording) {
                        HStack {
                            Image(systemName: "stop.fill")
                                .font(.title3)
                            Text("Stop Recording")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 60)
                        .background(.red)
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .clipShape(Capsule())
                        .hoverEffect(.automatic)
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
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 220, height: 80)
                    .background(.blue)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .clipShape(Capsule())
                    .hoverEffect(.automatic)
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isRecording)
    }
}