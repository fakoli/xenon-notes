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
    @State private var waveformValues: [CGFloat] = Array(repeating: 0.2, count: 40)
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<40, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorForLevel(waveformValues[index]),
                                    colorForLevel(waveformValues[index]).opacity(0.6)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: (geometry.size.width - 80) / 40, height: height * waveformValues[index])
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: waveformValues[index])
                }
            }
            .frame(height: height)
            .onAppear {
                startWaveformAnimation()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
        .frame(height: height)
    }
    
    private func colorForLevel(_ value: CGFloat) -> Color {
        if value > 0.8 {
            return .red
        } else if value > 0.6 {
            return .orange
        } else if value > 0.4 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func startWaveformAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateWaveform()
        }
    }
    
    private func updateWaveform() {
        let baseLevel = CGFloat(level)
        for i in 0..<waveformValues.count {
            let variation = CGFloat.random(in: -0.3...0.3)
            let newValue = max(0.1, min(1.0, baseLevel + variation))
            waveformValues[i] = newValue
        }
    }
}

struct ClassicAudioLevelView: View {
    let level: Float
    var height: CGFloat = 60
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.regularMaterial.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
                
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