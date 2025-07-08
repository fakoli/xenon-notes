//
//  APIKeysView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import SwiftData

struct APIKeysView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var apiKeyStatuses: [APIKeyService: APIKeyStatus] = [:]
    @State private var isCheckingStatus = false
    @State private var showExportImport = false
    
    struct APIKeyStatus {
        var hasKey: Bool
        var isValid: Bool?
        var lastChecked: Date?
    }
    
    var body: some View {
        Form {
            // Global API Keys Section
            Section {
                ForEach(APIKeyService.allCases, id: \.self) { service in
                    APIKeyRow(
                        service: service,
                        status: apiKeyStatuses[service] ?? APIKeyStatus(hasKey: false),
                        onTest: { testAPIKey(service) }
                    )
                }
            } header: {
                HStack {
                    Text("Global API Keys")
                    Spacer()
                    if isCheckingStatus {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            } footer: {
                Text("Global keys are shared across all profiles. Configure profile-specific keys in AI Profiles settings.")
            }
            
            // Management Section
            Section {
                Button(action: refreshAllStatuses) {
                    Label("Refresh All Status", systemImage: "arrow.clockwise")
                }
                .disabled(isCheckingStatus)
                
                Button(action: { showExportImport = true }) {
                    Label("Export/Import Settings", systemImage: "square.and.arrow.up")
                }
                
                NavigationLink(destination: ProfileManagementView()) {
                    Label("Manage AI Profiles", systemImage: "brain")
                }
                
                Button("Clear Global Keys", role: .destructive) {
                    clearGlobalKeys()
                }
            }
        }
        .navigationTitle("API Keys")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkAllKeyStatuses()
        }
        .sheet(isPresented: $showExportImport) {
            ExportImportView()
        }
    }
    
    private func checkAllKeyStatuses() {
        isCheckingStatus = true
        
        // Check global keys only
        for service in APIKeyService.allCases {
            do {
                let hasKey = try KeychainService.retrieveAPIKey(for: service) != nil
                apiKeyStatuses[service] = APIKeyStatus(hasKey: hasKey)
            } catch {
                apiKeyStatuses[service] = APIKeyStatus(hasKey: false)
            }
        }
        
        isCheckingStatus = false
    }
    
    private func testAPIKey(_ service: APIKeyService) {
        // Implementation depends on service
        // For now, just mark as tested
        var status = apiKeyStatuses[service] ?? APIKeyStatus(hasKey: false)
        status.isValid = true
        status.lastChecked = Date()
        apiKeyStatuses[service] = status
    }
    
    private func refreshAllStatuses() {
        checkAllKeyStatuses()
    }
    
    private func clearGlobalKeys() {
        do {
            // Only clear global keys, not profile keys
            for service in APIKeyService.allCases {
                try? KeychainService.deleteAPIKey(for: service)
            }
            checkAllKeyStatuses()
        } catch {
            print("Failed to clear keys: \(error)")
        }
    }
}

struct APIKeyRow: View {
    let service: APIKeyService
    let status: APIKeysView.APIKeyStatus
    let onTest: () -> Void
    
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.displayName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    StatusBadge(
                        text: status.hasKey ? "Configured" : "Not Set",
                        color: status.hasKey ? .green : .gray
                    )
                    
                    if let isValid = status.isValid {
                        StatusBadge(
                            text: isValid ? "Valid" : "Invalid",
                            color: isValid ? .green : .red
                        )
                    }
                    
                    if let lastChecked = status.lastChecked {
                        Text("Checked \(lastChecked.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(status.hasKey ? "Edit" : "Add") {
                    showingEditSheet = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if status.hasKey {
                    Button("Test", action: onTest)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditSheet) {
            APIKeyEditSheet(service: service)
        }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct ExportImportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Export/Import Settings")
                    .font(.largeTitle)
                    .padding()
                
                Text("This feature is coming soon")
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}