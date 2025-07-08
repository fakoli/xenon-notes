//
//  SpatialLayout.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI
import RealityKit

struct SpatialLayout {
    
    enum Layer {
        case background
        case content
        case overlay
        case floating
        
        var zOffset: CGFloat {
            switch self {
            case .background: return -200
            case .content: return 0
            case .overlay: return 100
            case .floating: return 200
            }
        }
    }
    
    enum Position {
        case center
        case topLeading
        case top
        case topTrailing
        case leading
        case trailing
        case bottomLeading
        case bottom
        case bottomTrailing
        
        func offset(in size: CGSize) -> CGSize {
            let halfWidth = size.width / 2
            let halfHeight = size.height / 2
            
            switch self {
            case .center:
                return CGSize(width: 0, height: 0)
            case .topLeading:
                return CGSize(width: -halfWidth, height: -halfHeight)
            case .top:
                return CGSize(width: 0, height: -halfHeight)
            case .topTrailing:
                return CGSize(width: halfWidth, height: -halfHeight)
            case .leading:
                return CGSize(width: -halfWidth, height: 0)
            case .trailing:
                return CGSize(width: halfWidth, height: 0)
            case .bottomLeading:
                return CGSize(width: -halfWidth, height: halfHeight)
            case .bottom:
                return CGSize(width: 0, height: halfHeight)
            case .bottomTrailing:
                return CGSize(width: halfWidth, height: halfHeight)
            }
        }
    }
    
    static let comfortableReach: CGFloat = 600
    static let maxReach: CGFloat = 1000
    static let minDistance: CGFloat = 300
    
    static func isWithinComfortZone(_ distance: CGFloat) -> Bool {
        distance >= minDistance && distance <= comfortableReach
    }
}

struct SpatialContainer<Content: View>: View {
    let content: Content
    let layer: SpatialLayout.Layer
    let position: SpatialLayout.Position
    
    init(
        layer: SpatialLayout.Layer = .content,
        position: SpatialLayout.Position = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.layer = layer
        self.position = position
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
                .offset(
                    x: position.offset(in: geometry.size).width,
                    y: position.offset(in: geometry.size).height
                )
                .offset(z: layer.zOffset)
        }
    }
}

struct OrnamentLayout: ViewModifier {
    enum OrnamentPosition {
        case leading
        case trailing
        case top
        case bottom
    }
    
    let position: OrnamentPosition
    let distance: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(z: distance)
            .rotation3DEffect(
                angle(for: position),
                axis: axis(for: position)
            )
    }
    
    private func angle(for position: OrnamentPosition) -> Angle {
        switch position {
        case .leading, .trailing:
            return .degrees(15)
        case .top, .bottom:
            return .degrees(10)
        }
    }
    
    private func axis(for position: OrnamentPosition) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch position {
        case .leading:
            return (0, -1, 0)
        case .trailing:
            return (0, 1, 0)
        case .top:
            return (1, 0, 0)
        case .bottom:
            return (-1, 0, 0)
        }
    }
}

extension View {
    func spatialContainer(
        layer: SpatialLayout.Layer = .content,
        position: SpatialLayout.Position = .center
    ) -> some View {
        SpatialContainer(layer: layer, position: position) {
            self
        }
    }
    
    func ornament(
        position: OrnamentLayout.OrnamentPosition,
        distance: CGFloat = 50
    ) -> some View {
        modifier(OrnamentLayout(position: position, distance: distance))
    }
}

struct SpatialGrid: Layout {
    let columns: Int
    let spacing: CGFloat
    let depth: CGFloat
    
    init(columns: Int = 3, spacing: CGFloat = GlassTheme.Spacing.medium, depth: CGFloat = 20) {
        self.columns = columns
        self.spacing = spacing
        self.depth = depth
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let _ = (proposal.width ?? 300 - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        let rows = (subviews.count + columns - 1) / columns
        let itemHeight = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 100
        let totalHeight = CGFloat(rows) * itemHeight + CGFloat(rows - 1) * spacing
        
        return CGSize(width: proposal.width ?? 300, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let itemWidth = (bounds.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        
        for (index, subview) in subviews.enumerated() {
            let row = index / columns
            let column = index % columns
            
            let x = bounds.minX + CGFloat(column) * (itemWidth + spacing) + itemWidth / 2
            let y = bounds.minY + CGFloat(row) * (subview.sizeThatFits(.unspecified).height + spacing) + subview.sizeThatFits(.unspecified).height / 2
            
            let _ = (row % 2 == 0) ? depth : -depth
            
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .center,
                proposal: ProposedViewSize(width: itemWidth, height: nil)
            )
        }
    }
}