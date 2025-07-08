//
//  AudioRecordingService.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import AVFoundation
import SwiftUI
import SwiftData
import Observation
internal import Combine

@MainActor
@Observable
final class AudioRecordingService: NSObject {
    var isRecording = false
    var recordingTime: TimeInterval = 0
    var audioLevel: Float = 0
    var currentRecording: Recording?
    var currentTranscript: String = ""
    
    private var audioEngine = AVAudioEngine()
    private var recordingSession: AVAudioSession?
    private var recordingTask: Task<Void, Never>?
    private var audioFile: AVAudioFile?
    private var currentChunkIndex = 0
    private var chunkStartTime: TimeInterval = 0
    private let chunkDuration: TimeInterval = 30.0 // 30 second chunks
    
    private var modelContext: ModelContext?
    var deepgramService: DeepgramService? = nil
    private var deepgramEnabled = false
    
    override init() {
        super.init()
        Task {
            await setupAudioSession()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func enableDeepgram(apiKey: String) async throws {
        // Create service if needed
        if deepgramService == nil {
            deepgramService = DeepgramService()
        }
        deepgramService?.setAPIKey(apiKey)
        // Don't connect immediately - wait until recording starts
        deepgramEnabled = true
    }
    
    func disableDeepgram() {
        deepgramService?.disconnect()
        deepgramService = nil
        deepgramEnabled = false
        currentTranscript = ""
    }
    
    private func connectDeepgram() async throws {
        guard let service = deepgramService else { return }
        
        if !service.isConnected {
            try await service.connect()
            
            // Observe transcript changes
            Task {
                for await transcript in service.$currentTranscript.values {
                    self.currentTranscript = transcript
                }
            }
        }
    }
    
    private func setupAudioSession() async {
        do {
            recordingSession = AVAudioSession.sharedInstance()
            try recordingSession?.setCategory(.record, mode: .measurement, options: [])
            
            let granted = await requestMicrophonePermission()
            if !granted {
                print("Microphone permission denied")
            }
            
            // Prepare the audio engine but don't activate session yet
            _ = audioEngine.inputNode
            audioEngine.prepare()
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(visionOS 1.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func startRecording() async throws {
        guard !isRecording else { return }
        
        // Activate audio session right before recording
        do {
            try recordingSession?.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
            throw error
        }
        
        isRecording = true
        recordingTime = 0
        currentChunkIndex = 0
        chunkStartTime = 0
        
        // Create new recording
        currentRecording = Recording(title: "Recording \(Date().formatted())")
        if let modelContext = modelContext, let recording = currentRecording {
            modelContext.insert(recording)
        }
        
        // Reset transcript
        currentTranscript = ""
        deepgramService?.reset()
        
        // Connect to Deepgram if enabled
        if deepgramEnabled {
            do {
                try await connectDeepgram()
            } catch {
                print("Failed to connect to Deepgram: \(error)")
                // Continue recording without transcription
            }
        }
        
        recordingTask = Task {
            await recordAudioChunks()
        }
    }
    
    private func recordAudioChunks() async {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let bufferSize: AVAudioFrameCount = 4096
        
        // Ensure no existing tap before installing
        inputNode.removeTap(onBus: 0)
        
        do {
            try startNewChunk(format: recordingFormat)
            
            var bufferCount = 0
            let buffersPerChunk = Int(chunkDuration * recordingFormat.sampleRate / Double(bufferSize))
            
            inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] buffer, time in
                guard let self = self else { return }
                
                Task { @MainActor in
                    self.processAudioBuffer(buffer)
                    
                    // Send to Deepgram if enabled and connected
                    if self.deepgramEnabled, let service = self.deepgramService, service.isConnected {
                        Task {
                            do {
                                try await service.processAudioBuffer(buffer)
                            } catch DeepgramError.notConnected {
                                // Silently ignore if not connected
                            } catch {
                                print("Deepgram processing error: \(error)")
                            }
                        }
                    }
                    
                    // Write to file
                    if let audioFile = self.audioFile {
                        do {
                            try audioFile.write(from: buffer)
                        } catch {
                            print("Error writing buffer: \(error)")
                        }
                    }
                    
                    bufferCount += 1
                    
                    // Check if we need to start a new chunk
                    if bufferCount >= buffersPerChunk {
                        bufferCount = 0
                        do {
                            try self.finalizeCurrentChunk()
                            try self.startNewChunk(format: recordingFormat)
                        } catch {
                            print("Error managing chunks: \(error)")
                        }
                    }
                }
            }
            
            try audioEngine.start()
            
            // Update recording time
            while !Task.isCancelled && isRecording {
                await updateRecordingTime()
                try await Task.sleep(for: .milliseconds(100))
            }
        } catch {
            print("Recording error: \(error)")
            await stopRecording()
        }
    }
    
    private func startNewChunk(format: AVAudioFormat) throws {
        let fileName = "chunk_\(currentChunkIndex)_\(UUID().uuidString).m4a"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioFile = try AVAudioFile(forWriting: url, settings: settings)
        
        // Create chunk model
        if let recording = currentRecording {
            let chunk = AudioChunk(index: currentChunkIndex, startTime: chunkStartTime)
            chunk.fileURL = url
            chunk.recording = recording
            recording.chunks.append(chunk)
        }
        
        currentChunkIndex += 1
        chunkStartTime = recordingTime
    }
    
    private func finalizeCurrentChunk() throws {
        guard let chunk = currentRecording?.chunks.last else { return }
        
        chunk.duration = recordingTime - chunk.startTime
        chunk.status = .completed
        audioFile = nil
    }
    
    func stopRecording() async {
        // First remove the tap before stopping the engine
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        
        recordingTask?.cancel()
        
        // Finalize last chunk
        do {
            try finalizeCurrentChunk()
        } catch {
            print("Error finalizing last chunk: \(error)")
        }
        
        // Update recording duration and transcript
        if let recording = currentRecording {
            recording.duration = recordingTime
            
            // Save transcript if we have one
            if deepgramEnabled, let service = deepgramService, !service.finalTranscript.isEmpty {
                let transcript = Transcript(rawText: service.finalTranscript)
                recording.transcript = transcript
                modelContext?.insert(transcript)
            }
        }
        
        // Save context
        do {
            try modelContext?.save()
        } catch {
            print("Error saving recording: \(error)")
        }
        
        isRecording = false
        audioFile = nil
        
        // Disconnect from Deepgram
        if deepgramEnabled {
            deepgramService?.disconnect()
        }
        
        // Deactivate audio session to save battery
        try? recordingSession?.setActive(false)
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let channelDataArray = Array(UnsafeBufferPointer(start: channelDataValue, count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        audioLevel = rms
    }
    
    private func updateRecordingTime() async {
        recordingTime += 0.1
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

extension AudioRecordingService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                print("Recording failed")
            }
        }
    }
}

