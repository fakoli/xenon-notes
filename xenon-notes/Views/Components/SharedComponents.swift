//
//  SharedComponents.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI

struct GlassStatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .foregroundStyle(color)
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 20
    
    init(cornerRadius: CGFloat = 16, padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
    }
}

struct PulsingDot: View {
    let color: Color
    let size: CGFloat
    @State private var isAnimating = false
    
    init(color: Color = .red, size: CGFloat = 12) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
            
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .opacity(0.3)
                .scaleEffect(isAnimating ? 2.5 : 1.0)
                .animation(
                    .easeInOut(duration: 1)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.3), radius: isPressed ? 5 : 10, y: isPressed ? 2 : 5)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .hoverEffect(.lift)
    }
}

struct SpatialDivider: View {
    var thickness: CGFloat = 0.5
    var color: Color = .white
    var opacity: Double = 0.1
    
    var body: some View {
        Rectangle()
            .fill(color.opacity(opacity))
            .frame(height: thickness)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func glowEffect(color: Color = .blue, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
    
    func floatingCard(offset: CGFloat = 20) -> some View {
        self
            .offset(z: offset)
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}