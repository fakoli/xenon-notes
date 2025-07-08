//
//  SettingsView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var appSettings: AppSettings?
    
    var body: some View {
        NavigationStack {
            List {
                // Transcription Section
                NavigationLink(destination: DeepgramSettingsView(appSettings: appSettings)) {
                    Label("Speech to Text", systemImage: "mic.fill")
                }
                
                // AI Profiles Section
                NavigationLink(destination: ProfileManagementView()) {
                    Label("AI Profiles", systemImage: "brain")
                }
                
                // API Keys Section
                NavigationLink(destination: APIKeysView()) {
                    Label("API Keys", systemImage: "key.fill")
                }
                
                // General Settings Section
                NavigationLink(destination: GeneralSettingsView(appSettings: appSettings)) {
                    Label("General", systemImage: "gearshape.fill")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        appSettings = AppSettings.loadOrCreate(in: modelContext)
    }
    
    private func saveSettings() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}

// Placeholder for General Settings
struct GeneralSettingsView: View {
    let appSettings: AppSettings?
    
    var body: some View {
        Form {
            Section("Recording") {
                if let settings = appSettings {
                    Picker("Recording Quality", selection: Binding(
                        get: { settings.recordingQuality },
                        set: { settings.recordingQuality = $0 }
                    )) {
                        ForEach(RecordingQuality.allCases, id: \.self) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                    
                    Toggle("Show transcript while recording", isOn: Binding(
                        get: { settings.showTranscriptWhileRecording },
                        set: { settings.showTranscriptWhileRecording = $0 }
                    ))
                }
            }
            
            Section("Processing") {
                if let settings = appSettings {
                    Toggle("Auto-process transcripts", isOn: Binding(
                        get: { settings.autoProcessTranscripts },
                        set: { settings.autoProcessTranscripts = $0 }
                    ))
                    
                    Toggle("Process when recording ends", isOn: Binding(
                        get: { settings.processOnRecordingEnd },
                        set: { settings.processOnRecordingEnd = $0 }
                    ))
                    .disabled(!settings.autoProcessTranscripts)
                }
            }
            
            Section("Data") {
                Button("Clear All API Keys", role: .destructive) {
                    clearAllAPIKeys()
                }
            }
        }
        .navigationTitle("General")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func clearAllAPIKeys() {
        do {
            try KeychainService.clearAllKeys()
        } catch {
            print("Failed to clear API keys: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [AppSettings.self, Profile.self])
}