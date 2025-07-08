//
//  ProcessingProfileSelectionView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import SwiftData

struct ProcessingProfileSelectionView: View {
    let recording: Recording
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Profile.name) private var profiles: [Profile]
    @State private var selectedProfile: Profile?
    @State private var isProcessing = false
    @State private var processingError: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if profiles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "brain")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("No AI Profiles")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Create a profile in Settings to process your transcripts")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Go to Settings") {
                            dismiss()
                            // Note: In a real app, you'd navigate to settings
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Select a profile to process the transcript")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.top)
                            
                            ForEach(profiles.filter { $0.isActive }) { profile in
                                ProfileSelectionCard(
                                    profile: profile,
                                    isSelected: selectedProfile?.id == profile.id,
                                    onSelect: {
                                        selectedProfile = profile
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: processTranscript) {
                            if isProcessing {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Processing...")
                                }
                            } else {
                                Text("Process Transcript")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .disabled(selectedProfile == nil || isProcessing)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .disabled(isProcessing)
                    }
                    .padding()
                    .background(.regularMaterial)
                }
            }
            .navigationTitle("Process with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isProcessing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .alert("Processing Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(processingError ?? "Unknown error occurred")
        }
    }
    
    private func processTranscript() {
        guard let profile = selectedProfile,
              let transcript = recording.transcript else { return }
        
        isProcessing = true
        processingError = nil
        
        Task {
            do {
                // Create appropriate LLM service
                let llmService = LLMServiceFactory.createService(for: profile.llmService)
                
                // Process the transcript
                let result = try await llmService.processTranscript(
                    transcript.rawText,
                    with: profile
                )
                
                // Link result to recording
                result.recording = recording
                recording.processedResults.append(result)
                recording.processingProfile = profile
                
                // Save to database
                modelContext.insert(result)
                try modelContext.save()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    processingError = error.localizedDescription
                    showError = true
                    isProcessing = false
                }
            }
        }
    }
}

struct ProfileSelectionCard: View {
    let profile: Profile
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: profile.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    HStack(spacing: 8) {
                        Text(profile.llmService.rawValue)
                            .font(.caption)
                        
                        Text("•")
                        
                        Text(profile.modelName)
                            .font(.caption)
                    }
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            
            Text(profile.systemPrompt)
                .font(.caption)
                .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                .lineLimit(2)
        }
        .padding()
        .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onSelect()
        }
    }
}