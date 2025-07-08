//
//  Recording.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftData
import Foundation

@Model
final class Recording {
    var id: UUID
    var title: String
    var createdAt: Date
    var duration: TimeInterval
    var audioFileURL: URL?
    
    @Relationship(deleteRule: .cascade)
    var chunks: [AudioChunk]
    
    @Relationship(deleteRule: .cascade)
    var transcript: Transcript?
    
    @Relationship(deleteRule: .nullify)
    var processingProfile: Profile?
    
    @Relationship(deleteRule: .cascade)
    var processedResults: [ProcessedResult]
    
    init(title: String = "New Recording") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.duration = 0
        self.chunks = []
        self.processedResults = []
    }
}