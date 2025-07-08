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
    @State private var hoveredProfile: Profile?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                if profiles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "brain")
                            .font(.system(size: 80))
                            .foregroundStyle(.white.opacity(0.3))
                            .symbolEffect(.bounce.up, value: true)
                        
                        Text("No AI Profiles")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("Create a profile in Settings to process your transcripts")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Go to Settings") {
                            dismiss()
                            // Note: In a real app, you'd navigate to settings
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(minWidth: 200, minHeight: 60)
                        .hoverEffect(.automatic)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Select a profile to process the transcript")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.top, 30)
                            
                            // Profile grid
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(profiles) { profile in
                                    ProfileSelectionCard(
                                        profile: profile,
                                        isSelected: selectedProfile?.id == profile.id,
                                        isHovered: hoveredProfile?.id == profile.id,
                                        onSelect: {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedProfile = profile
                                            }
                                        }
                                    )
                                    .onHover { isHovered in
                                        hoveredProfile = isHovered ? profile : nil
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 20)
                        }
                    }
                    
                    // Action buttons with glass background
                    VStack(spacing: 16) {
                        Button(action: processTranscript) {
                            if isProcessing {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                    Text("Processing...")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            } else {
                                Text("Process Transcript")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(selectedProfile != nil ? Color.blue : Color.white.opacity(0.2))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .disabled(selectedProfile == nil || isProcessing)
                        .hoverEffect(.automatic)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(.regularMaterial.opacity(0.6))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .disabled(isProcessing)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial.opacity(0.8))
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
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
    let isHovered: Bool
    let onSelect: () -> Void
    
    @State private var hasAPIKey = false
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack(alignment: .leading, spacing: 16) {
                headerView
                profileInfoView
                Spacer()
                statusIndicatorsView
            }
            .padding(20)
        }
        .frame(height: 200)
        .scaleEffect(isHovered || isSelected ? 1.02 : 1.0)
        .offset(z: isHovered || isSelected ? 20 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
        .onTapGesture {
            onSelect()
        }
        .onAppear {
            checkAPIKey()
        }
    }
    
    private var backgroundView: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 0.5)
                    )
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.white.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: profile.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var profileInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(profile.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                Label(profile.llmService.rawValue, systemImage: "cpu")
                    .font(.system(size: 12, weight: .medium))
                
                Text("•")
                
                Text(profile.modelName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.65))
            
            Text(profile.systemPrompt)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(2)
                .padding(.top, 4)
        }
    }
    
    private var statusIndicatorsView: some View {
        HStack(spacing: 8) {
            if hasAPIKey {
                GlassStatusBadge(text: "API Key", color: .green)
            } else {
                GlassStatusBadge(text: "No Key", color: .orange)
            }
            
            if profile.isActive {
                GlassStatusBadge(text: "Active", color: .blue)
            }
        }
    }
    
    private func checkAPIKey() {
        do {
            // Check for profile-specific key first
            if let _ = try KeychainService.retrieveProfileAPIKey(
                profileID: profile.apiKeyIdentifier,
                service: profile.llmService
            ) {
                hasAPIKey = true
                return
            }
            
            // Fall back to global key
            let apiKeyService: APIKeyService
            switch profile.llmService {
            case .openAI:
                apiKeyService = .openAI
            case .anthropic:
                apiKeyService = .anthropic
            case .gemini:
                apiKeyService = .gemini
            case .custom:
                hasAPIKey = true // Assume custom has key
                return
            }
            
            if let _ = try KeychainService.retrieveAPIKey(for: apiKeyService) {
                hasAPIKey = true
            }
        } catch {
            hasAPIKey = false
        }
    }
}