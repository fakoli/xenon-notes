//
//  ProfileManagementView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import SwiftData

struct ProfileManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt, order: .reverse) private var profiles: [Profile]
    @State private var showingAddProfile = false
    @State private var selectedProfile: Profile?
    @State private var appSettings: AppSettings?
    
    var body: some View {
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
        .sheet(isPresented: $showingAddProfile) {
            ProfileEditView(profile: nil)
        }
        .sheet(item: $selectedProfile) { profile in
            ProfileEditView(profile: profile)
        }
        .navigationTitle("AI Profiles")
        .navigationBarTitleDisplayMode(.inline)
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

#Preview {
    ProfileManagementView()
        .modelContainer(for: [Profile.self, AppSettings.self])
}