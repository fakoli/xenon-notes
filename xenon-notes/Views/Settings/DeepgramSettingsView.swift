//
//  DeepgramSettingsView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI

struct DeepgramSettingsView: View {
    let appSettings: AppSettings?
    
    @State private var apiKey = ""
    @State private var showAPIKey = false
    @State private var isTestingConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var savedAPIKey = ""
    @State private var showingMicTest = false
    @State private var showingTranscriptionTest = false
    
    enum ConnectionStatus {
        case unknown, testing, connected, failed
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .testing: return .orange
            case .connected: return .green
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .testing: return "arrow.triangle.2.circlepath"
            case .connected: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var text: String {
            switch self {
            case .unknown: return "Not configured"
            case .testing: return "Testing..."
            case .connected: return "Connected"
            case .failed: return "Connection failed"
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Deepgram API Key")
                        .font(.headline)
                    
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
                    
                    if !savedAPIKey.isEmpty && apiKey.isEmpty {
                        Text("API key is saved in Keychain")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Button("Save Key") {
                            saveAPIKey()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKey.isEmpty)
                        
                        Button("Test Connection") {
                            testConnection()
                        }
                        .buttonStyle(.bordered)
                        .disabled(apiKey.isEmpty && savedAPIKey.isEmpty)
                        
                        Spacer()
                        
                        // Connection Status
                        HStack(spacing: 4) {
                            Image(systemName: connectionStatus.icon)
                            Text(connectionStatus.text)
                                .font(.caption)
                        }
                        .foregroundStyle(connectionStatus.color)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("API Configuration")
            } footer: {
                Text("Get your API key from [deepgram.com](https://console.deepgram.com)")
            }
            
            Section("Transcription Settings") {
                if let settings = appSettings {
                    Toggle("Enable Deepgram", isOn: Binding(
                        get: { settings.deepgramEnabled },
                        set: { settings.deepgramEnabled = $0 }
                    ))
                    .disabled(savedAPIKey.isEmpty && apiKey.isEmpty)
                    
                    Picker("Model", selection: Binding(
                        get: { settings.deepgramModel },
                        set: { settings.deepgramModel = $0 }
                    )) {
                        Text("Nova 2").tag("nova-2")
                        Text("Nova").tag("nova")
                        Text("Enhanced").tag("enhanced")
                        Text("Base").tag("base")
                    }
                    .disabled(!settings.deepgramEnabled)
                    
                    Picker("Language", selection: Binding(
                        get: { settings.deepgramLanguage },
                        set: { settings.deepgramLanguage = $0 }
                    )) {
                        Text("English").tag("en")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                        Text("German").tag("de")
                        Text("Italian").tag("it")
                        Text("Portuguese").tag("pt")
                        Text("Japanese").tag("ja")
                        Text("Korean").tag("ko")
                        Text("Chinese").tag("zh")
                    }
                    .disabled(!settings.deepgramEnabled)
                }
            }
            
            Section {
                Button(action: { showingMicTest = true }) {
                    Label("Test Microphone", systemImage: "mic")
                }
                // Disable if both API keys are empty
                .disabled(savedAPIKey.isEmpty && apiKey.isEmpty)

                Button(action: { showingTranscriptionTest = true }) {
                    Label("Test Transcription", systemImage: "waveform")
                }
                .disabled(connectionStatus != .connected)
            } header: {
                Text("Testing")
            } footer: {
                Text("Test your microphone and transcription setup")
            }
            
            Section("Advanced") {
                Link("View Documentation", destination: URL(string: "https://developers.deepgram.com/docs")!)
                Link("API Dashboard", destination: URL(string: "https://console.deepgram.com")!)
            }
        }
        .navigationTitle("Speech to Text")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAPIKey()
        }
        .sheet(isPresented: $showingMicTest) {
            MicrophoneTestView()
        }
        .sheet(isPresented: $showingTranscriptionTest) {
            TranscriptionTestView(apiKey: savedAPIKey.isEmpty ? apiKey : savedAPIKey)
        }
    }
    
    private func loadAPIKey() {
        do {
            if let key = try KeychainService.retrieveAPIKey(for: .deepgram) {
                savedAPIKey = key
                connectionStatus = .connected
            }
        } catch {
            print("Failed to load API key: \(error)")
        }
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        // Trim whitespace from the API key
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try KeychainService.saveAPIKey(trimmedKey, for: .deepgram)
            savedAPIKey = trimmedKey
            apiKey = "" // Clear the field after saving
            connectionStatus = .unknown
            print("API key saved successfully")
        } catch {
            print("Failed to save API key: \(error)")
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = .testing
        
        Task {
            do {
                let keyToTest = apiKey.isEmpty ? savedAPIKey : apiKey
                let service = DeepgramService()
                service.setAPIKey(keyToTest)
                
                // Just validate the API key with a quick connect/disconnect
                try await service.connect()
                
                await MainActor.run {
                    connectionStatus = .connected
                    isTestingConnection = false
                }
                
                // Disconnect after test - this is just to validate the key
                service.disconnect()
            } catch {
                await MainActor.run {
                    connectionStatus = .failed
                    isTestingConnection = false
                }
                print("Connection test failed: \(error)")
            }
        }
    }
}

#Preview {
    DeepgramSettingsView(appSettings: AppSettings())
}

