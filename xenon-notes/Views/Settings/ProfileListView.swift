//
//  ProfileListView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import SwiftData

struct ProfileListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt, order: .reverse) private var profiles: [Profile]
    @State private var showingAddProfile = false
    @State private var selectedProfile: Profile?
    @State private var appSettings: AppSettings?
    
    var body: some View {
        NavigationStack {
            List {
                if profiles.isEmpty {
                    ContentUnavailableView {
                        Label("No AI Profiles", systemImage: "brain")
                    } description: {
                        Text("Create profiles to process your transcripts with different AI models")
                    } actions: {
                        Button("Create Profile") {
                            showingAddProfile = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(profiles) { profile in
                            ProfileRow(
                                profile: profile,
                                isActive: profile.id == appSettings?.activeProfileID,
                                onSetActive: {
                                    setActiveProfile(profile)
                                }
                            )
                            .onTapGesture {
                                selectedProfile = profile
                            }
                        }
                        .onDelete(perform: deleteProfiles)
                    } header: {
                        HStack {
                            Text("AI Profiles")
                            Spacer()
                            Text("\(profiles.count) total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section {
                        Button(action: { showingAddProfile = true }) {
                            Label("Add Profile", systemImage: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("AI Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !profiles.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingAddProfile = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddProfile) {
            ProfileEditView(profile: nil)
        }
        .sheet(item: $selectedProfile) { profile in
            ProfileEditView(profile: profile)
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        appSettings = AppSettings.loadOrCreate(in: modelContext)
    }
    
    private func setActiveProfile(_ profile: Profile) {
        appSettings?.activeProfileID = profile.id
        
        // Mark all profiles as inactive
        for p in profiles {
            p.isActive = false
        }
        
        // Mark selected profile as active
        profile.isActive = true
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to set active profile: \(error)")
        }
    }
    
    private func deleteProfiles(offsets: IndexSet) {
        for index in offsets {
            let profile = profiles[index]
            
            // Clear the API key from keychain
            do {
                try KeychainService.deleteProfileAPIKey(
                    profileID: profile.apiKeyIdentifier,
                    service: profile.llmService
                )
            } catch {
                print("Failed to delete API key: \(error)")
            }
            
            // If this was the active profile, clear it
            if profile.id == appSettings?.activeProfileID {
                appSettings?.activeProfileID = nil
            }
            
            modelContext.delete(profile)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete profiles: \(error)")
        }
    }
}

struct ProfileRow: View {
    let profile: Profile
    let isActive: Bool
    let onSetActive: () -> Void
    
    @State private var hasAPIKey = false
    @State private var lastUsed: Date?
    @State private var showingTestView = false
    @State private var showingEditView = false
    
    var body: some View {
        HStack {
            // Icon
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: profile.icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 40)
                
                if hasAPIKey {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 8))
                                .foregroundStyle(.white)
                        )
                }
            }
            
            // Profile Info
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                
                HStack(spacing: 6) {
                    Text(profile.llmService.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(profile.modelName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    if isActive {
                        StatusBadge(text: "Active", color: .green)
                    }
                    
                    if !hasAPIKey {
                        StatusBadge(text: "No API Key", color: .orange)
                    }
                    
                    if let lastUsed = lastUsed {
                        Text("Used \(lastUsed.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button(action: { showingEditView = true }) {
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("Edit Profile")
                
                Button(action: { showingTestView = true }) {
                    Image(systemName: "play.circle")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .disabled(!hasAPIKey)
                .help("Test Profile")
                
                if !isActive {
                    Button("Activate") {
                        onSetActive()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            checkAPIKey()
            loadLastUsed()
        }
        .sheet(isPresented: $showingTestView) {
            ProfileTestView(profile: profile)
        }
        .sheet(isPresented: $showingEditView) {
            ProfileEditView(profile: profile)
        }
    }
    
    private func checkAPIKey() {
        do {
            hasAPIKey = try KeychainService.retrieveProfileAPIKey(
                profileID: profile.apiKeyIdentifier,
                service: profile.llmService
            ) != nil
        } catch {
            hasAPIKey = false
        }
    }
    
    private func loadLastUsed() {
        // Check if this profile has any processed results
        if let latestResult = profile.processedResults.sorted(by: { $0.createdAt > $1.createdAt }).first {
            lastUsed = latestResult.createdAt
        }
    }
}

#Preview {
    ProfileListView()
        .modelContainer(for: [Profile.self, AppSettings.self])
}