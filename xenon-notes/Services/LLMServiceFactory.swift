//
//  LLMServiceFactory.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import Foundation

enum LLMServiceFactory {
    static func createService(for llmService: LLMService) -> LLMServiceProtocol {
        switch llmService {
        case .openAI:
            return OpenAIService()
        case .anthropic:
            return AnthropicService()
        case .gemini:
            // Placeholder for future implementation
            return OpenAIService() // Fallback for now
        case .custom:
            // Placeholder for custom implementations
            return OpenAIService() // Fallback for now
        }
    }
}