//
//  ProfileTestView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI

struct ProfileTestView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var testText = "This is a sample transcript for testing. The quick brown fox jumps over the lazy dog. Please summarize this text and extract any key points."
    @State private var isProcessing = false
    @State private var result: String?
    @State private var error: String?
    @State private var processingTime: TimeInterval?
    
    private let sampleTexts = [
        "Meeting": "Team discussed Q4 goals. Sarah will lead the marketing campaign. Budget approved for $50k. Next meeting scheduled for Friday at 2pm.",
        "Medical": "Patient presents with mild headache and fatigue. Temperature 98.6F. Blood pressure 120/80. Prescribed rest and hydration.",
        "Technical": "Fixed bug in authentication module. Updated dependencies to latest versions. Performance improved by 23%. Need to add unit tests.",
        "Legal": "Contract reviewed and approved by legal team. Terms include 30-day payment period. Non-disclosure agreement attached.",
        "Creative": "The sunset painted the sky in brilliant hues of orange and pink. Birds chirped their evening songs as the day came to a peaceful close."
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Info
                    VStack(spacing: 8) {
                        Image(systemName: profile.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        
                        Text(profile.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text(profile.llmService.rawValue)
                            Text("•")
                            Text(profile.modelName)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    
                    // Test Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test Input")
                            .font(.headline)
                        
                        TextEditor(text: $testText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Sample Text Buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(sampleTexts.keys.sorted(), id: \.self) { key in
                                    Button(key) {
                                        testText = sampleTexts[key] ?? ""
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // System Prompt Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Prompt")
                            .font(.headline)
                        
                        Text(profile.systemPrompt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                    
                    // Test Button
                    Button(action: runTest) {
                        if isProcessing {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Processing...")
                            }
                        } else {
                            Text("Run Test")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isProcessing || testText.isEmpty)
                    
                    // Results
                    if let result = result {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Result")
                                    .font(.headline)
                                
                                Spacer()
                                
                                if let time = processingTime {
                                    Text("\(String(format: "%.1f", time))s")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Text(result)
                                .textSelection(.enabled)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal)
                    }
                    
                    if let error = error {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Error")
                                .font(.headline)
                                .foregroundStyle(.red)
                            
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Test Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func runTest() {
        isProcessing = true
        result = nil
        error = nil
        processingTime = nil
        
        Task {
            do {
                let llmService = LLMServiceFactory.createService(for: profile.llmService)
                let startTime = Date()
                
                // Create a temporary transcript for testing
                let testResult = try await llmService.processTranscript(testText, with: profile)
                
                await MainActor.run {
                    self.result = testResult.processedText
                    self.processingTime = Date().timeIntervalSince(startTime)
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isProcessing = false
                }
            }
        }
    }
}