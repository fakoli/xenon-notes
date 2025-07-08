//
//  ProfileEditView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import SwiftData

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let profile: Profile?
    
    @State private var name = ""
    @State private var icon = "brain"
    @State private var llmService = LLMService.openAI
    @State private var modelName = ""
    @State private var useGlobalAPIKey = true
    @State private var profileSpecificKey = ""
    @State private var showAPIKey = false
    @State private var systemPrompt = ""
    @State private var customEndpoint = ""
    @State private var hasExistingProfileKey = false
    @State private var hasGlobalKey = false
    @State private var temperature = 0.7
    @State private var maxTokens = ""
    @State private var topP = 1.0
    @State private var frequencyPenalty = 0.0
    @State private var presencePenalty = 0.0
    @State private var showAdvancedSettings = false
    @State private var showingTestView = false
    
    private let defaultPrompts = [
        "Default": "You are a helpful assistant that processes voice transcriptions.",
        "Meeting Notes": "You are an expert at summarizing meeting transcripts. Extract key decisions, action items, and important discussions.",
        "Medical": "You are a medical transcription assistant. Focus on accuracy and use proper medical terminology.",
        "Legal": "You are a legal transcription assistant. Maintain verbatim accuracy and note any legal terminology.",
        "Creative": "You are a creative writing assistant. Transform transcripts into well-structured, engaging prose.",
        "Technical": "You are a technical documentation expert. Extract technical details and format them clearly."
    ]
    
    private let iconOptions = [
        "brain", "brain.head.profile", "sparkles", "doc.text",
        "bubble.left.and.text.bubble.right", "text.quote",
        "doc.richtext", "note.text", "text.book.closed"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Profile Information") {
                    TextField("Profile Name", text: $name)
                    
                    // Icon Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(iconOptions, id: \.self) { iconName in
                                Button(action: { icon = iconName }) {
                                    Image(systemName: iconName)
                                        .font(.title2)
                                        .foregroundStyle(icon == iconName ? .white : .primary)
                                        .frame(width: 44, height: 44)
                                        .background(icon == iconName ? Color.blue : Color.secondary.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // LLM Configuration
                Section {
                    Picker("Service", selection: $llmService) {
                        ForEach(LLMService.allCases, id: \.self) { service in
                            Text(service.rawValue).tag(service)
                        }
                    }
                    .onChange(of: llmService) { _, newValue in
                        modelName = newValue.defaultModel
                        checkGlobalKey()
                    }
                    
                    if llmService != .custom {
                        Picker("Model", selection: $modelName) {
                            ForEach(llmService.availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                    } else {
                        TextField("Model Name", text: $modelName)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("API Endpoint", text: $customEndpoint)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API Key Configuration")
                            .font(.headline)
                        
                        if hasGlobalKey {
                            Toggle("Use Global API Key", isOn: $useGlobalAPIKey)
                                .font(.subheadline)
                            
                            if useGlobalAPIKey {
                                Label("Using global \(llmService.rawValue) key", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        } else {
                            Text("No global API key found")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            
                            Button(action: {}) {
                                Label("Configure Global Keys", systemImage: "key.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if !useGlobalAPIKey || !hasGlobalKey {
                            Divider()
                            
                            Text("Profile-Specific Key")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                if showAPIKey {
                                    TextField("Enter API Key", text: $profileSpecificKey)
                                        .textFieldStyle(.roundedBorder)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                } else {
                                    SecureField("Enter API Key", text: $profileSpecificKey)
                                        .textFieldStyle(.roundedBorder)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                
                                Button(action: { showAPIKey.toggle() }) {
                                    Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            if hasExistingProfileKey && profileSpecificKey.isEmpty {
                                Text("Profile-specific key is saved")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("AI Service")
                }
                
                // System Prompt
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Prompt")
                            .font(.headline)
                        
                        TextEditor(text: $systemPrompt)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Prompt Templates
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(defaultPrompts.keys.sorted(), id: \.self) { key in
                                    Button(key) {
                                        systemPrompt = defaultPrompts[key] ?? ""
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Processing Instructions")
                } footer: {
                    Text("This prompt will be used to process transcripts with the selected AI service")
                }
                
                // Advanced Settings
                Section {
                    DisclosureGroup("Advanced Settings", isExpanded: $showAdvancedSettings) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Temperature
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Temperature")
                                    Spacer()
                                    Text(String(format: "%.1f", temperature))
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $temperature, in: 0...2, step: 0.1)
                                Text("Controls randomness: 0 = deterministic, 2 = very random")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Max Tokens
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Max Tokens (optional)")
                                TextField("Leave empty for default", text: $maxTokens)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                Text("Maximum length of the generated response")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Top P
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Top P")
                                    Spacer()
                                    Text(String(format: "%.1f", topP))
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $topP, in: 0...1, step: 0.1)
                                Text("Nucleus sampling: only consider tokens above this probability")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Frequency Penalty
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Frequency Penalty")
                                    Spacer()
                                    Text(String(format: "%.1f", frequencyPenalty))
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $frequencyPenalty, in: -2...2, step: 0.1)
                                Text("Reduces repetition of frequently used words")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Presence Penalty
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Presence Penalty")
                                    Spacer()
                                    Text(String(format: "%.1f", presencePenalty))
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $presencePenalty, in: -2...2, step: 0.1)
                                Text("Encourages talking about new topics")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(profile == nil ? "New Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty || (!hasGlobalKey && profileSpecificKey.isEmpty && !hasExistingProfileKey))
                }
                
                if hasGlobalKey || hasExistingProfileKey || !profileSpecificKey.isEmpty {
                    ToolbarItem(placement: .automatic) {
                        Button("Test") {
                            showingTestView = true
                        }
                    }
                }
            }
        }
        .onAppear {
            loadProfile()
        }
        .sheet(isPresented: $showingTestView) {
            if let existingProfile = profile {
                ProfileTestView(profile: existingProfile)
            } else {
                // Create temporary profile for testing
                ProfileTestView(profile: createTemporaryProfile())
            }
        }
    }
    
    private func loadProfile() {
        // Check for global key first
        checkGlobalKey()
        
        guard let profile = profile else {
            // Set default for new profile
            systemPrompt = defaultPrompts["Default"] ?? ""
            modelName = llmService.defaultModel
            return
        }
        
        name = profile.name
        icon = profile.icon
        llmService = profile.llmService
        modelName = profile.modelName
        systemPrompt = profile.systemPrompt
        customEndpoint = profile.customEndpoint ?? ""
        temperature = profile.temperature
        if let tokens = profile.maxTokens {
            maxTokens = String(tokens)
        }
        topP = profile.topP
        frequencyPenalty = profile.frequencyPenalty
        presencePenalty = profile.presencePenalty
        
        // Check if profile-specific API key exists
        do {
            if let _ = try KeychainService.retrieveProfileAPIKey(
                profileID: profile.apiKeyIdentifier,
                service: profile.llmService
            ) {
                hasExistingProfileKey = true
                useGlobalAPIKey = false  // If profile has its own key, use it
            }
        } catch {
            print("Failed to check for existing API key: \(error)")
        }
    }
    
    private func checkGlobalKey() {
        // Map LLMService to APIKeyService
        let apiKeyService: APIKeyService
        switch llmService {
        case .openAI:
            apiKeyService = .openAI
        case .anthropic:
            apiKeyService = .anthropic
        case .gemini:
            apiKeyService = .gemini
        case .custom:
            return  // No global key for custom
        }
        
        do {
            if let _ = try KeychainService.retrieveAPIKey(for: apiKeyService) {
                hasGlobalKey = true
            }
        } catch {
            hasGlobalKey = false
        }
    }
    
    private func saveProfile() {
        let profileToSave: Profile
        
        if let existingProfile = profile {
            // Update existing
            existingProfile.name = name
            existingProfile.icon = icon
            existingProfile.llmService = llmService
            existingProfile.modelName = modelName
            existingProfile.systemPrompt = systemPrompt
            existingProfile.customEndpoint = llmService == .custom ? customEndpoint : nil
            existingProfile.temperature = temperature
            existingProfile.maxTokens = Int(maxTokens)
            existingProfile.topP = topP
            existingProfile.frequencyPenalty = frequencyPenalty
            existingProfile.presencePenalty = presencePenalty
            profileToSave = existingProfile
        } else {
            // Create new
            let newProfile = Profile(name: name, icon: icon, llmService: llmService)
            newProfile.modelName = modelName
            newProfile.systemPrompt = systemPrompt
            newProfile.customEndpoint = llmService == .custom ? customEndpoint : nil
            newProfile.temperature = temperature
            newProfile.maxTokens = Int(maxTokens)
            newProfile.topP = topP
            newProfile.frequencyPenalty = frequencyPenalty
            newProfile.presencePenalty = presencePenalty
            modelContext.insert(newProfile)
            profileToSave = newProfile
        }
        
        // Save profile-specific API key if provided and not using global
        if !useGlobalAPIKey && !profileSpecificKey.isEmpty {
            do {
                try KeychainService.saveProfileAPIKey(
                    profileSpecificKey,
                    profileID: profileToSave.apiKeyIdentifier,
                    service: profileToSave.llmService
                )
            } catch {
                print("Failed to save API key: \(error)")
            }
        } else if useGlobalAPIKey && hasExistingProfileKey {
            // If switching to global key, remove profile-specific key
            do {
                try KeychainService.deleteProfileAPIKey(
                    profileID: profileToSave.apiKeyIdentifier,
                    service: profileToSave.llmService
                )
            } catch {
                print("Failed to delete profile key: \(error)")
            }
        }
        
        // Save to database
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
    
    private func createTemporaryProfile() -> Profile {
        let tempProfile = Profile(name: name, icon: icon, llmService: llmService)
        tempProfile.modelName = modelName
        tempProfile.systemPrompt = systemPrompt
        tempProfile.temperature = temperature
        tempProfile.maxTokens = Int(maxTokens)
        tempProfile.topP = topP
        tempProfile.frequencyPenalty = frequencyPenalty
        tempProfile.presencePenalty = presencePenalty
        
        // Save temporary API key if provided
        if !profileSpecificKey.isEmpty {
            try? KeychainService.saveProfileAPIKey(
                profileSpecificKey,
                profileID: tempProfile.apiKeyIdentifier,
                service: tempProfile.llmService
            )
        }
        
        return tempProfile
    }
}

#Preview {
    ProfileEditView(profile: nil)
        .modelContainer(for: Profile.self)
}