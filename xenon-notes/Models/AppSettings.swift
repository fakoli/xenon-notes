//
//  AppSettings.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftData
import Foundation

@Model
final class AppSettings {
    var id: UUID
    
    // Deepgram Settings
    var deepgramEnabled: Bool
    var deepgramModel: String
    var deepgramLanguage: String
    
    // Active Profile
    var activeProfileID: UUID?
    
    // Processing Settings
    var autoProcessTranscripts: Bool
    var processOnRecordingEnd: Bool
    
    // UI Settings
    var showTranscriptWhileRecording: Bool
    var recordingQuality: RecordingQuality
    
    // First Launch
    var hasCompletedOnboarding: Bool
    var lastUpdated: Date
    
    init() {
        self.id = UUID()
        self.deepgramEnabled = false
        self.deepgramModel = "nova-2"
        self.deepgramLanguage = "en"
        self.autoProcessTranscripts = false
        self.processOnRecordingEnd = false
        self.showTranscriptWhileRecording = true
        self.recordingQuality = .high
        self.hasCompletedOnboarding = false
        self.lastUpdated = Date()
    }
    
    // Singleton pattern for app-wide settings
    @MainActor
    static func loadOrCreate(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let settings = try context.fetch(descriptor)
            if let existingSettings = settings.first {
                return existingSettings
            }
        } catch {
            print("Error fetching settings: \(error)")
        }
        
        // Create new settings if none exist
        let newSettings = AppSettings()
        context.insert(newSettings)
        
        do {
            try context.save()
        } catch {
            print("Error saving new settings: \(error)")
        }
        
        return newSettings
    }
}

enum RecordingQuality: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var sampleRate: Double {
        switch self {
        case .low:
            return 22050
        case .medium:
            return 44100
        case .high:
            return 48000
        }
    }
    
    var bitRate: Int {
        switch self {
        case .low:
            return 64000
        case .medium:
            return 128000
        case .high:
            return 192000
        }
    }
}