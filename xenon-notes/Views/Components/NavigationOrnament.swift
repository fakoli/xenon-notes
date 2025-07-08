//
//  NavigationOrnament.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI

struct NavigationOrnament: View {
    @Binding var showingSettings: Bool
    @Binding var isRecording: Bool
    let appSettings: AppSettings?
    let onNewRecording: () -> Void
    
    @State private var expandedSection: NavigationSection? = nil
    @State private var hoveredButton: NavigationButton? = nil
    
    enum NavigationSection: String, CaseIterable {
        case recording = "Recording"
        case library = "Library"
        case tools = "Tools"
    }
    
    enum NavigationButton: String {
        case newRecording = "mic.fill"
        case settings = "gearshape.fill"
        case immersive = "visionpro"
        case search = "magnifyingglass"
        case sort = "arrow.up.arrow.down"
        case filter = "line.3.horizontal.decrease.circle"
    }
    
    var body: some View {
        HStack(spacing: 24) {
            // Recording Section
            OrnamentSection(
                icon: "mic.circle.fill",
                title: "Record",
                isExpanded: expandedSection == .recording,
                isRecording: isRecording
            ) {
                expandedSection = expandedSection == .recording ? nil : .recording
            } content: {
                OrnamentButton(
                    icon: NavigationButton.newRecording.rawValue,
                    label: "New Recording",
                    isHovered: hoveredButton == .newRecording,
                    isActive: isRecording,
                    action: onNewRecording
                )
                .onHover { isHovered in
                    hoveredButton = isHovered ? .newRecording : nil
                }
            }
            
            // Library Section
            OrnamentSection(
                icon: "folder.circle.fill",
                title: "Library",
                isExpanded: expandedSection == .library
            ) {
                expandedSection = expandedSection == .library ? nil : .library
            } content: {
                HStack(spacing: 12) {
                    OrnamentButton(
                        icon: NavigationButton.search.rawValue,
                        label: "Search",
                        isHovered: hoveredButton == .search,
                        action: {}
                    )
                    .onHover { isHovered in
                        hoveredButton = isHovered ? .search : nil
                    }
                    
                    OrnamentButton(
                        icon: NavigationButton.sort.rawValue,
                        label: "Sort",
                        isHovered: hoveredButton == .sort,
                        action: {}
                    )
                    .onHover { isHovered in
                        hoveredButton = isHovered ? .sort : nil
                    }
                    
                    OrnamentButton(
                        icon: NavigationButton.filter.rawValue,
                        label: "Filter",
                        isHovered: hoveredButton == .filter,
                        action: {}
                    )
                    .onHover { isHovered in
                        hoveredButton = isHovered ? .filter : nil
                    }
                }
            }
            
            Spacer()
            
            // Tools Section
            OrnamentSection(
                icon: "wrench.and.screwdriver.fill",
                title: "Tools",
                isExpanded: expandedSection == .tools
            ) {
                expandedSection = expandedSection == .tools ? nil : .tools
            } content: {
                HStack(spacing: 12) {
                    OrnamentButton(
                        icon: NavigationButton.settings.rawValue,
                        label: "Settings",
                        isHovered: hoveredButton == .settings,
                        isActive: appSettings?.deepgramEnabled == true,
                        action: { showingSettings = true }
                    )
                    .onHover { isHovered in
                        hoveredButton = isHovered ? .settings : nil
                    }
                    
                    ImmersiveOrnamentButton(
                        isHovered: hoveredButton == .immersive
                    )
                    .onHover { isHovered in
                        hoveredButton = isHovered ? .immersive : nil
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: expandedSection)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: hoveredButton)
    }
}

struct OrnamentSection<Content: View>: View {
    let icon: String
    let title: String
    let isExpanded: Bool
    var isRecording: Bool = false
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onToggle) {
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(isRecording ? .red : .white)
                        .symbolEffect(.bounce, value: isExpanded)
                    
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            
            if isExpanded {
                content()
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
    }
}

struct OrnamentButton: View {
    let icon: String
    let label: String
    let isHovered: Bool
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isActive ? .blue : .white)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                
                if isHovered {
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 60, height: isHovered ? 60 : 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial.opacity(isHovered ? 0.6 : 0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
    }
}

struct ImmersiveOrnamentButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    let isHovered: Bool
    
    var body: some View {
        Button(action: toggleImmersiveSpace) {
            VStack(spacing: 6) {
                Image(systemName: "visionpro")
                    .font(.system(size: 24))
                    .foregroundStyle(appModel.immersiveSpaceState == .open ? .blue : .white)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                
                if isHovered {
                    Text(appModel.immersiveSpaceState == .open ? "Exit" : "Immersive")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 60, height: isHovered ? 60 : 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial.opacity(isHovered ? 0.6 : 0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(appModel.immersiveSpaceState == .inTransition)
        .opacity(appModel.immersiveSpaceState == .inTransition ? 0.5 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
    }
    
    private func toggleImmersiveSpace() {
        Task { @MainActor in
            switch appModel.immersiveSpaceState {
            case .open:
                appModel.immersiveSpaceState = .inTransition
                await dismissImmersiveSpace()
            case .closed:
                appModel.immersiveSpaceState = .inTransition
                switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                case .opened:
                    break
                case .userCancelled, .error:
                    fallthrough
                @unknown default:
                    appModel.immersiveSpaceState = .closed
                }
            case .inTransition:
                break
            }
        }
    }
}

#Preview {
    NavigationOrnament(
        showingSettings: .constant(false),
        isRecording: .constant(false),
        appSettings: nil,
        onNewRecording: {}
    )
    .padding()
    .background(Color.black)
}