//
//  DeepgramService.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import Foundation
@preconcurrency import AVFoundation
internal import Combine

// Deepgram response models
struct DeepgramResponse: Codable {
    let channel: Channel?
    let metadata: Metadata?
    let type: String?
    
    struct Channel: Codable {
        let alternatives: [Alternative]
    }
    
    struct Alternative: Codable {
        let transcript: String
        let confidence: Double
        let words: [Word]?
    }
    
    struct Word: Codable {
        let word: String
        let start: Double
        let end: Double
        let confidence: Double
    }
    
    struct Metadata: Codable {
        let requestId: String?
        let modelInfo: ModelInfo?
        
        enum CodingKeys: String, CodingKey {
            case requestId = "request_id"
            case modelInfo = "model_info"
        }
    }
    
    struct ModelInfo: Codable {
        let name: String
        let version: String
        let arch: String
    }
}

@MainActor
class DeepgramService: NSObject, ObservableObject {
    
    @Published var isConnected = false
    @Published var currentTranscript = ""
    @Published var finalTranscript = ""
    @Published var confidence: Float = 0.0
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var apiKey: String = ""
    
    // Audio format for Deepgram
    private let sampleRate = 16000.0
    private let channels = 1
    
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    func setAPIKey(_ key: String) {
        self.apiKey = key
    }
    
    func connect() async throws {
        guard !apiKey.isEmpty else {
            throw DeepgramError.missingAPIKey
        }
        
        // Log for debugging (remove in production)
        print("Connecting to Deepgram with API key: \(String(apiKey.prefix(8)))...")
        
        guard var components = URLComponents(string: "wss://api.deepgram.com/v1/listen") else {
            throw DeepgramError.invalidURL
        }
        
        // Configure Deepgram parameters
        components.queryItems = [
            URLQueryItem(name: "encoding", value: "linear16"),
            URLQueryItem(name: "sample_rate", value: "\(Int(sampleRate))"),
            URLQueryItem(name: "channels", value: "\(channels)"),
            URLQueryItem(name: "model", value: "nova-2"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "smart_format", value: "true"),
            URLQueryItem(name: "punctuate", value: "true"),
            URLQueryItem(name: "interim_results", value: "true"),
            URLQueryItem(name: "endpointing", value: "300")
        ]
        
        guard let url = components.url else {
            throw DeepgramError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("xenon-notes", forHTTPHeaderField: "User-Agent")
        
        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Wait for connection to be established
        webSocketTask?.sendPing(pongReceiveHandler: { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("WebSocket ping failed: \(error)")
                    self?.isConnected = false
                } else {
                    self?.isConnected = true
                    print("Deepgram WebSocket connected successfully")

                    // Start receiving messages
                    Task {
                        await self?.receiveMessages()
                    }
                }
            }
        })
    }
    
    func disconnect() {
        isConnected = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        currentTranscript = ""
    }
    
    func sendAudioData(_ audioData: Data) async throws {
        guard let webSocketTask = webSocketTask else {
            throw DeepgramError.notConnected
        }
        
        // Check if the task is still valid
        if webSocketTask.state != .running {
            throw DeepgramError.notConnected
        }
        
        let message = URLSessionWebSocketTask.Message.data(audioData)
        try await webSocketTask.send(message)
    }
    
    private func receiveMessages() async {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            while isConnected {
                let message = try await webSocketTask.receive()
                
                switch message {
                case .string(let text):
                    processTranscriptResponse(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        processTranscriptResponse(text)
                    }
                @unknown default:
                    break
                }
            }
        } catch {
            print("WebSocket receive error: \(error)")
            isConnected = false
        }
    }
    
    private func processTranscriptResponse(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }
        
        do {
            let response = try JSONDecoder().decode(DeepgramResponse.self, from: data)
            
            if let alternative = response.channel?.alternatives.first {
                currentTranscript = alternative.transcript
                confidence = Float(alternative.confidence)
                
                // If this is a final transcript (not interim), append to final transcript
                if response.type == "Results" && !alternative.transcript.isEmpty {
                    if !finalTranscript.isEmpty {
                        finalTranscript += " "
                    }
                    finalTranscript += alternative.transcript
                }
            }
        } catch {
            print("Failed to decode Deepgram response: \(error)")
        }
    }
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) async throws {
        // Convert buffer to 16kHz mono for Deepgram
        let convertedBuffer = try convertBuffer(buffer, toSampleRate: sampleRate)
        
        // Convert to Data
        guard let audioData = pcmBufferToData(convertedBuffer) else {
            throw DeepgramError.audioConversionFailed
        }
        
        try await sendAudioData(audioData)
    }
    
    private func convertBuffer(_ buffer: AVAudioPCMBuffer, toSampleRate sampleRate: Double) throws -> AVAudioPCMBuffer {
        let inputFormat = buffer.format
        
        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, 
                                              sampleRate: sampleRate,
                                              channels: 1,
                                              interleaved: false) else {
            throw DeepgramError.audioFormatError
        }
        
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw DeepgramError.audioConverterError
        }
        
        let frameCapacity = UInt32((Double(buffer.frameLength) / inputFormat.sampleRate) * sampleRate)
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCapacity) else {
            throw DeepgramError.bufferAllocationError
        }
        
        var error: NSError?
        converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if let error = error {
            throw error
        }
        
        return convertedBuffer
    }
    
    private func pcmBufferToData(_ buffer: AVAudioPCMBuffer) -> Data? {
        let audioFormat = buffer.format
        guard let channelData = buffer.int16ChannelData else { return nil }
        
        let channelCount = Int(audioFormat.channelCount)
        let frameLength = Int(buffer.frameLength)
        let bytesPerFrame = channelCount * MemoryLayout<Int16>.size
        
        var data = Data()
        data.reserveCapacity(frameLength * bytesPerFrame)
        
        for frame in 0..<frameLength {
            for channel in 0..<channelCount {
                let sample = channelData[channel][frame]
                withUnsafeBytes(of: sample) { bytes in
                    data.append(contentsOf: bytes)
                }
            }
        }
        
        return data
    }
    
    func reset() {
        currentTranscript = ""
        finalTranscript = ""
        confidence = 0.0
    }
}

extension DeepgramService: URLSessionWebSocketDelegate {
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task { @MainActor in
            print("Deepgram WebSocket connected")
            isConnected = true
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in
            print("Deepgram WebSocket disconnected")
            isConnected = false
        }
    }
}

enum DeepgramError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case notConnected
    case audioConversionFailed
    case audioFormatError
    case audioConverterError
    case bufferAllocationError
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Deepgram API key is missing"
        case .invalidURL:
            return "Invalid Deepgram URL"
        case .notConnected:
            return "Not connected to Deepgram"
        case .audioConversionFailed:
            return "Failed to convert audio buffer"
        case .audioFormatError:
            return "Failed to create audio format"
        case .audioConverterError:
            return "Failed to create audio converter"
        case .bufferAllocationError:
            return "Failed to allocate audio buffer"
        }
    }
}

