//
//  Profile.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftData
import Foundation

enum LLMService: String, Codable, CaseIterable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case gemini = "Google Gemini"
    case custom = "Custom"
    
    var baseURL: String? {
        switch self {
        case .openAI:
            return "https://api.openai.com/v1"
        case .anthropic:
            return "https://api.anthropic.com/v1"
        case .gemini:
            return "https://generativelanguage.googleapis.com/v1"
        case .custom:
            return nil
        }
    }
    
    var defaultModel: String {
        switch self {
        case .openAI:
            return "gpt-4o"
        case .anthropic:
            return "claude-3-5-sonnet-20241022"
        case .gemini:
            return "gemini-2.0-flash-exp"
        case .custom:
            return ""
        }
    }
    
    var availableModels: [String] {
        switch self {
        case .openAI:
            return [
                "gpt-4o",
                "gpt-4o-mini",
                "gpt-4-turbo",
                "gpt-4-turbo-2024-04-09",
                "gpt-4",
                "gpt-3.5-turbo",
                "gpt-3.5-turbo-0125",
                "o1",
                "o1-mini",
                "o1-preview"
            ]
        case .anthropic:
            return [
                "claude-3-5-sonnet-20241022",
                "claude-3-5-haiku-20241022",
                "claude-3-opus-20240229",
                "claude-3-sonnet-20240229",
                "claude-3-haiku-20240307"
            ]
        case .gemini:
            return [
                "gemini-2.0-flash-exp",
                "gemini-1.5-pro",
                "gemini-1.5-pro-002",
                "gemini-1.5-flash",
                "gemini-1.5-flash-002",
                "gemini-1.5-flash-8b"
            ]
        case .custom:
            return []
        }
    }
}

@Model
final class Profile: @unchecked Sendable {
    var id: UUID
    var name: String
    var icon: String
    var llmService: LLMService
    var modelName: String
    var apiKeyIdentifier: String
    var systemPrompt: String
    var temperature: Double
    var maxTokens: Int?
    var topP: Double
    var frequencyPenalty: Double
    var presencePenalty: Double
    var isActive: Bool
    var createdAt: Date
    var customEndpoint: String?
    
    @Relationship(inverse: \Recording.processingProfile)
    var recordings: [Recording]
    
    @Relationship(deleteRule: .cascade)
    var processedResults: [ProcessedResult]
    
    init(name: String, icon: String = "brain", llmService: LLMService = .openAI) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.llmService = llmService
        self.modelName = llmService.defaultModel
        self.apiKeyIdentifier = UUID().uuidString
        self.systemPrompt = "You are a helpful assistant that processes voice transcriptions."
        self.temperature = 0.7
        self.maxTokens = nil
        self.topP = 1.0
        self.frequencyPenalty = 0.0
        self.presencePenalty = 0.0
        self.isActive = true
        self.createdAt = Date()
        self.recordings = []
        self.processedResults = []
    }
}

