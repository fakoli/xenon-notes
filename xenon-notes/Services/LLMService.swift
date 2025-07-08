//
//  LLMService.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import Foundation

protocol LLMServiceProtocol {
    func processTranscript(
        _ transcript: String,
        with profile: Profile
    ) async throws -> ProcessedResult
}

enum LLMServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case networkError(String)
    case rateLimitExceeded
    case invalidConfiguration
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not found. Please configure it in Settings."
        case .invalidResponse:
            return "Invalid response from AI service"
        case .networkError(let message):
            return "Network error: \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidConfiguration:
            return "Invalid service configuration"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        }
    }
}

// Base implementation with shared utilities
class BaseLLMService {
    
    func createProcessedResult(
        responseText: String,
        profile: Profile,
        model: String,
        processingTime: TimeInterval,
        originalTranscript: String
    ) -> ProcessedResult {
        let result = ProcessedResult(
            processedText: responseText,
            prompt: buildFullPrompt(systemPrompt: profile.systemPrompt, transcript: originalTranscript),
            modelUsed: model,
            temperature: profile.temperature,
            maxTokens: profile.maxTokens,
            processingTime: processingTime
        )
        result.profile = profile
        return result
    }
    
    func buildFullPrompt(systemPrompt: String, transcript: String) -> String {
        return """
        \(systemPrompt)
        
        Transcript:
        \(transcript)
        """
    }
    
    func measureTime<T>(operation: () async throws -> T) async rethrows -> (result: T, time: TimeInterval) {
        let start = Date()
        let result = try await operation()
        let elapsed = Date().timeIntervalSince(start)
        return (result, elapsed)
    }
}