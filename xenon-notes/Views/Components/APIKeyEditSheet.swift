//
//  APIKeyEditSheet.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI

struct APIKeyEditSheet: View {
    let service: APIKeyService
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey = ""
    @State private var showAPIKey = false
    @State private var isLoading = false
    @State private var hasExistingKey = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(service.displayName, systemImage: iconForService(service))
                            .font(.headline)
                        
                        if hasExistingKey {
                            Text("An API key is already configured. Enter a new key to replace it.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            if showAPIKey {
                                TextField("Enter API Key", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Enter API Key", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            
                            Button(action: { showAPIKey.toggle() }) {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("API Key Configuration")
                } footer: {
                    Text(footerText(for: service))
                }
                
                if hasExistingKey {
                    Section {
                        Button("Remove API Key", role: .destructive) {
                            removeAPIKey()
                        }
                    }
                }
            }
            .navigationTitle(hasExistingKey ? "Edit API Key" : "Add API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
        }
        .onAppear {
            checkExistingKey()
        }
    }
    
    private func iconForService(_ service: APIKeyService) -> String {
        switch service {
        case .deepgram:
            return "mic.fill"
        case .openAI:
            return "cpu"
        case .anthropic:
            return "brain"
        case .gemini:
            return "sparkles"
        }
    }
    
    private func footerText(for service: APIKeyService) -> String {
        switch service {
        case .deepgram:
            return "Get your API key from console.deepgram.com"
        case .openAI:
            return "Get your API key from platform.openai.com"
        case .anthropic:
            return "Get your API key from console.anthropic.com"
        case .gemini:
            return "Get your API key from makersuite.google.com"
        }
    }
    
    private func checkExistingKey() {
        do {
            hasExistingKey = try KeychainService.retrieveAPIKey(for: service) != nil
        } catch {
            hasExistingKey = false
        }
    }
    
    private func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try KeychainService.saveAPIKey(trimmedKey, for: service)
            dismiss()
        } catch {
            print("Failed to save API key: \(error)")
        }
    }
    
    private func removeAPIKey() {
        do {
            try KeychainService.deleteAPIKey(for: service)
            dismiss()
        } catch {
            print("Failed to remove API key: \(error)")
        }
    }
}