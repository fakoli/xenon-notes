//
//  ProcessedResult.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftData
import Foundation

@Model
final class ProcessedResult {
    var id: UUID
    var createdAt: Date
    var processedText: String
    var prompt: String
    var modelUsed: String
    var temperature: Double
    var maxTokens: Int?
    var processingTime: TimeInterval
    
    @Relationship(deleteRule: .nullify)
    var recording: Recording?
    
    @Relationship(deleteRule: .nullify)
    var profile: Profile?
    
    init(
        processedText: String,
        prompt: String,
        modelUsed: String,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        processingTime: TimeInterval = 0
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.processedText = processedText
        self.prompt = prompt
        self.modelUsed = modelUsed
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.processingTime = processingTime
    }
}

