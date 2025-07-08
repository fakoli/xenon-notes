//
//  AudioChunk.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftData
import Foundation

enum ChunkStatus: String, Codable {
    case recording
    case queued
    case transcribing
    case completed
    case failed
}

@Model
final class AudioChunk {
    var id: UUID
    var index: Int
    var startTime: TimeInterval
    var duration: TimeInterval
    var fileURL: URL?
    var status: ChunkStatus
    
    @Relationship(inverse: \Recording.chunks)
    var recording: Recording?
    
    @Relationship(deleteRule: .cascade)
    var transcriptSegment: TranscriptSegment?
    
    init(index: Int, startTime: TimeInterval) {
        self.id = UUID()
        self.index = index
        self.startTime = startTime
        self.duration = 0
        self.status = .recording
    }
}