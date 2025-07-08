//
//  AudioLevelView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI

struct AudioLevelView: View {
    let level: Float
    var height: CGFloat = 60
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                
                Capsule()
                    .fill(LinearGradient(
                        colors: [.blue, .blue.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geometry.size.width * CGFloat(min(level * 2, 1.0)))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
        .frame(height: height)
    }
}