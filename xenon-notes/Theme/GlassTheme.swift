//
//  GlassTheme.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI

struct GlassTheme {
    
    enum Vibrancy {
        case primary
        case secondary
        case tertiary
        
        var opacity: Double {
            switch self {
            case .primary: return 1.0
            case .secondary: return 0.65
            case .tertiary: return 0.35
            }
        }
    }
    
    enum Spacing {
        static let minimum: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let huge: CGFloat = 48
        
        static let minimumTapTarget: CGFloat = 60
        static let standardButtonSize: CGFloat = 44
        static let largeButtonSize: CGFloat = 80
    }
    
    enum Typography {
        static func extraLargeTitle1() -> Font {
            .system(size: 48, weight: .bold, design: .default)
        }
        
        static func extraLargeTitle2() -> Font {
            .system(size: 36, weight: .bold, design: .default)
        }
        
        static func largeTitle() -> Font {
            .system(size: 34, weight: .bold, design: .default)
        }
        
        static func title() -> Font {
            .system(size: 28, weight: .bold, design: .default)
        }
        
        static func title2() -> Font {
            .system(size: 22, weight: .bold, design: .default)
        }
        
        static func title3() -> Font {
            .system(size: 20, weight: .semibold, design: .default)
        }
        
        static func headline() -> Font {
            .system(size: 17, weight: .semibold, design: .default)
        }
        
        static func body() -> Font {
            .system(size: 17, weight: .medium, design: .default)
        }
        
        static func callout() -> Font {
            .system(size: 16, weight: .medium, design: .default)
        }
        
        static func subheadline() -> Font {
            .system(size: 15, weight: .medium, design: .default)
        }
        
        static func footnote() -> Font {
            .system(size: 13, weight: .medium, design: .default)
        }
        
        static func caption() -> Font {
            .system(size: 12, weight: .medium, design: .default)
        }
        
        static func caption2() -> Font {
            .system(size: 11, weight: .medium, design: .default)
        }
    }
    
    enum Animation {
        static let standard = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let quick = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.8)
        static let smooth = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.9)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
    
    enum Depth {
        static let near: CGFloat = 0.1
        static let standard: CGFloat = 0.2
        static let medium: CGFloat = 0.3
        static let far: CGFloat = 0.5
        static let distant: CGFloat = 1.0
    }
}

struct GlassMaterial: ViewModifier {
    let vibrancy: GlassTheme.Vibrancy
    let isInteractive: Bool
    
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .hoverEffect(isInteractive ? .automatic : .lift)
    }
}

struct GlassButton: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: GlassTheme.Spacing.minimumTapTarget,
                   minHeight: GlassTheme.Spacing.minimumTapTarget)
            .background(.regularMaterial.opacity(isPressed ? 0.6 : 0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(isPressed ? 0.05 : 0.1), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(GlassTheme.Animation.quick, value: isPressed)
            .hoverEffect(.automatic)
    }
}

struct VibrancyText: ViewModifier {
    let vibrancy: GlassTheme.Vibrancy
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white.opacity(vibrancy.opacity))
    }
}

extension View {
    func glassMaterial(vibrancy: GlassTheme.Vibrancy = .primary,
                      isInteractive: Bool = false) -> some View {
        modifier(GlassMaterial(vibrancy: vibrancy, isInteractive: isInteractive))
    }
    
    func glassButton(isPressed: Bool = false) -> some View {
        modifier(GlassButton(isPressed: isPressed))
    }
    
    func vibrancyText(_ vibrancy: GlassTheme.Vibrancy = .primary) -> some View {
        modifier(VibrancyText(vibrancy: vibrancy))
    }
    
    func glassCard(depth: CGFloat = GlassTheme.Depth.standard) -> some View {
        self
            .padding(GlassTheme.Spacing.medium)
            .glassMaterial()
            .offset(z: depth * 100)
    }
}

struct FocusEffect: ViewModifier {
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .brightness(isFocused ? 0.1 : 0)
            .animation(GlassTheme.Animation.quick, value: isFocused)
            .focusable()
            .focused($isFocused)
    }
}

extension View {
    func focusEffect() -> some View {
        modifier(FocusEffect())
    }
}