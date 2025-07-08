//
//  MicrophoneTestView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import AVFoundation

struct MicrophoneTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var audioEngine = AVAudioEngine()
    @State private var isMonitoring = false
    @State private var audioLevel: Float = 0
    @State private var peakLevel: Float = 0
    @State private var hasPermission = false
    @State private var permissionError: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Status
                VStack(spacing: 16) {
                    Image(systemName: hasPermission ? "mic.fill" : "mic.slash.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(hasPermission ? .green : .red)
                        .symbolEffect(.variableColor, isActive: isMonitoring)
                    
                    Text(hasPermission ? "Microphone Ready" : "Microphone Permission Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let error = permissionError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                // Audio Level Indicator
                if hasPermission {
                    VStack(spacing: 20) {
                        // Level Meter
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Audio Level")
                                .font(.headline)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.secondary.opacity(0.2))
                                    
                                    // Current Level
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(levelColor(for: audioLevel))
                                        .frame(width: geometry.size.width * CGFloat(audioLevel))
                                        .animation(.easeOut(duration: 0.1), value: audioLevel)
                                    
                                    // Peak Level Indicator
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: 2)
                                        .offset(x: geometry.size.width * CGFloat(peakLevel))
                                }
                                .frame(height: 30)
                            }
                            .frame(height: 30)
                            
                            HStack {
                                Text("Silent")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Loud")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Level Text
                        HStack(spacing: 40) {
                            VStack {
                                Text("Current")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(audioLevel * 100))%")
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                            
                            VStack {
                                Text("Peak")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(peakLevel * 100))%")
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        // Instructions
                        Text(isMonitoring ? "Speak into your microphone" : "Tap Start to begin monitoring")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Control Button
                if hasPermission {
                    Button(action: toggleMonitoring) {
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                } else {
                    Button(action: requestPermission) {
                        Text("Request Microphone Access")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                }
                
                Button("Reset Peak Level") {
                    peakLevel = 0
                }
                .buttonStyle(.bordered)
                .disabled(!isMonitoring)
            }
            .padding()
            .navigationTitle("Microphone Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        stopMonitoring()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkPermission()
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    private func levelColor(for level: Float) -> Color {
        switch level {
        case 0..<0.3:
            return .green
        case 0.3..<0.7:
            return .yellow
        default:
            return .red
        }
    }
    
    private func checkPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            hasPermission = true
        case .denied:
            hasPermission = false
            permissionError = "Microphone access denied. Please enable in Settings."
        case .undetermined:
            hasPermission = false
        @unknown default:
            hasPermission = false
        }
    }
    
    private func requestPermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                hasPermission = granted
                if !granted {
                    permissionError = "Microphone access denied. Please enable in Settings."
                }
            }
        }
    }
    
    private func toggleMonitoring() {
        if isMonitoring {
            stopMonitoring()
        } else {
            startMonitoring()
        }
    }
    
    private func startMonitoring() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true)
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.removeTap(onBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.processAudioBuffer(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isMonitoring = true
        } catch {
            permissionError = "Failed to start monitoring: \(error.localizedDescription)"
        }
    }
    
    private func stopMonitoring() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        isMonitoring = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let channelDataArray = Array(UnsafeBufferPointer(start: channelDataValue, count: Int(buffer.frameLength)))
        
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let normalizedLevel = min(rms * 10, 1.0) // Normalize and cap at 1.0
        
        DispatchQueue.main.async {
            self.audioLevel = normalizedLevel
            if normalizedLevel > self.peakLevel {
                self.peakLevel = normalizedLevel
            }
        }
    }
}