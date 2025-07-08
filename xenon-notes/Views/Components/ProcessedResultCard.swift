//
//  ProcessedResultCard.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI

struct ProcessedResultCard: View {
    let result: ProcessedResult
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let profile = result.profile {
                        HStack(spacing: 6) {
                            Image(systemName: profile.icon)
                                .font(.caption)
                            Text(profile.name)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.blue)
                    }
                    
                    Text(result.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(result.modelUsed)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if result.processingTime > 0 {
                        Text("\(String(format: "%.1f", result.processingTime))s")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                Divider()
                    .padding(.vertical, 4)
                
                Text(result.processedText)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding(.bottom, 4)
                
                if !result.prompt.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prompt Used")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Text(result.prompt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}