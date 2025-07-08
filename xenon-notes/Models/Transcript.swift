//
//  Transcript.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftData
import Foundation

@Model
final class Transcript {
    var id: UUID
    var rawText: String
    var processedText: String?
    var language: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(inverse: \Recording.transcript)
    var recording: Recording?
    
    @Relationship(deleteRule: .cascade)
    var segments: [TranscriptSegment]
    
    init(rawText: String = "", language: String = "en") {
        self.id = UUID()
        self.rawText = rawText
        self.language = language
        self.createdAt = Date()
        self.updatedAt = Date()
        self.segments = []
    }
}

@Model
final class TranscriptSegment {
    var id: UUID
    var text: String
    var startTime: TimeInterval
    var endTime: TimeInterval
    var confidence: Float
    
    @Relationship(inverse: \Transcript.segments)
    var transcript: Transcript?
    
    @Relationship(inverse: \AudioChunk.transcriptSegment)
    var audioChunk: AudioChunk?
    
    init(text: String, startTime: TimeInterval, endTime: TimeInterval, confidence: Float = 1.0) {
        self.id = UUID()
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
    }
}