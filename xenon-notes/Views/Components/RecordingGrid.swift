//
//  RecordingGrid.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import SwiftData

struct RecordingGrid: View {
    let recordings: [Recording]
    @Binding var selectedRecording: Recording?
    let isRecording: Bool
    
    @State private var hoveredRecording: Recording?
    @State private var gridLayout = GridLayout.list
    
    enum GridLayout: String, CaseIterable {
        case list = "List"
        case grid = "Grid"
        case cards = "Cards"
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .grid: return "square.grid.2x2"
            case .cards: return "rectangle.stack"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Layout switcher
            HStack {
                Text("Recordings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(GridLayout.allCases, id: \.self) { layout in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                gridLayout = layout
                            }
                        }) {
                            Image(systemName: layout.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(gridLayout == layout ? .blue : .white.opacity(0.6))
                                .frame(width: 36, height: 36)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.regularMaterial.opacity(gridLayout == layout ? 0.6 : 0.3))
                        )
                        .hoverEffect(.highlight)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Content based on layout
            switch gridLayout {
            case .list:
                listView
            case .grid:
                gridView
            case .cards:
                cardsView
            }
        }
    }
    
    var listView: some View {
        LazyVStack(spacing: 16) {
            ForEach(recordings) { recording in
                RecordingRow(recording: recording)
                    .onTapGesture {
                        if !isRecording {
                            selectedRecording = recording
                        }
                    }
                    .opacity(isRecording ? 0.5 : 1.0)
                    .allowsHitTesting(!isRecording)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .padding(.horizontal, 24)
    }
    
    var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(recordings) { recording in
                    RecordingGridItem(
                        recording: recording,
                        isHovered: hoveredRecording?.id == recording.id
                    )
                    .onTapGesture {
                        if !isRecording {
                            selectedRecording = recording
                        }
                    }
                    .onHover { isHovered in
                        hoveredRecording = isHovered ? recording : nil
                    }
                    .opacity(isRecording ? 0.5 : 1.0)
                    .allowsHitTesting(!isRecording)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    var cardsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(recordings) { recording in
                    RecordingCard(
                        recording: recording,
                        isHovered: hoveredRecording?.id == recording.id
                    )
                    .onTapGesture {
                        if !isRecording {
                            selectedRecording = recording
                        }
                    }
                    .onHover { isHovered in
                        hoveredRecording = isHovered ? recording : nil
                    }
                    .opacity(isRecording ? 0.5 : 1.0)
                    .allowsHitTesting(!isRecording)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
        }
    }
}

struct RecordingGridItem: View {
    let recording: Recording
    let isHovered: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and duration
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                
                Spacer()
                
                Text(formatDuration(recording.duration))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.regularMaterial.opacity(0.6))
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recording.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                
                if let transcript = recording.transcript {
                    Text(transcript.rawText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineLimit(3)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Status badges
            HStack(spacing: 8) {
                if recording.transcript != nil {
                    GlassStatusBadge(text: "Transcribed", color: .green)
                }
                
                if !recording.processedResults.isEmpty {
                    GlassStatusBadge(text: "AI Processed", color: .blue)
                }
            }
        }
        .padding(20)
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 0.5)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .offset(z: isHovered ? 20 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct RecordingCard: View {
    let recording: Recording
    let isHovered: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                
                Spacer()
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue.opacity(0.8))
            }
            
            // Duration and status
            HStack {
                Label(formatDuration(recording.duration), systemImage: "timer")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if recording.transcript != nil {
                        Image(systemName: "text.quote")
                            .foregroundStyle(.green)
                    }
                    
                    if !recording.processedResults.isEmpty {
                        Image(systemName: "brain")
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            Divider()
                .background(.white.opacity(0.1))
            
            // Transcript preview
            if let transcript = recording.transcript {
                Text(transcript.rawText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(4)
            } else {
                Text("No transcript available")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .italic()
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 320, height: 240)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 0.5)
                )
        )
        .rotation3DEffect(
            .degrees(isHovered ? 5 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .offset(z: isHovered ? 30 : 0)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}