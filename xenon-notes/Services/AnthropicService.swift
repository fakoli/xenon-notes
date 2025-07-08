//
//  AnthropicService.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import Foundation

class AnthropicService: BaseLLMService, LLMServiceProtocol {
    
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    func processTranscript(
        _ transcript: String,
        with profile: Profile
    ) async throws -> ProcessedResult {
        // Try profile-specific key first, then fall back to global key
        var apiKey: String?
        
        // Check for profile-specific key
        apiKey = try? KeychainService.retrieveProfileAPIKey(
            profileID: profile.apiKeyIdentifier,
            service: .anthropic
        )
        
        // If no profile key, try global key
        if apiKey == nil {
            apiKey = try? KeychainService.retrieveAPIKey(for: .anthropic)
        }
        
        guard let finalAPIKey = apiKey else {
            throw LLMServiceError.missingAPIKey
        }
        
        // Build request
        let request = try buildRequest(
            transcript: transcript,
            profile: profile,
            apiKey: finalAPIKey
        )
        
        // Send request and measure time
        let (responseText, processingTime) = try await measureTime {
            try await sendRequest(request)
        }
        
        // Create and return result
        return createProcessedResult(
            responseText: responseText,
            profile: profile,
            model: profile.modelName,
            processingTime: processingTime,
            originalTranscript: transcript
        )
    }
    
    private func buildRequest(
        transcript: String,
        profile: Profile,
        apiKey: String
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw LLMServiceError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let messages: [[String: String]] = [
            ["role": "user", "content": transcript]
        ]
        
        var body: [String: Any] = [
            "model": profile.modelName,
            "messages": messages,
            "system": profile.systemPrompt,
            "temperature": profile.temperature,
            "top_p": profile.topP
        ]
        
        if let maxTokens = profile.maxTokens {
            body["max_tokens"] = maxTokens
        } else {
            body["max_tokens"] = 4096 // Anthropic requires this parameter
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    private func sendRequest(_ request: URLRequest) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMServiceError.networkError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try parseResponse(data)
        case 429:
            throw LLMServiceError.rateLimitExceeded
        case 401:
            throw LLMServiceError.missingAPIKey
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMServiceError.processingFailed("Status \(httpResponse.statusCode): \(errorMessage)")
        }
    }
    
    private func parseResponse(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw LLMServiceError.invalidResponse
        }
        
        return text
    }
}