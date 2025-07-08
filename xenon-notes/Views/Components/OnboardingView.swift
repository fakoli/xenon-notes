//
//  OnboardingView.swift
//  xenon-notes
//
//  Created on 7/8/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showingSettings = false
    
    private let steps = [
        OnboardingStep(
            title: "Welcome to Xenon Notes",
            subtitle: "Your AI-powered voice recording assistant",
            systemImage: "mic.and.signal.meter",
            description: "Record voice notes with real-time transcription and AI processing"
        ),
        OnboardingStep(
            title: "Set Up Transcription",
            subtitle: "Configure Deepgram for speech-to-text",
            systemImage: "waveform",
            description: "Get your free API key from deepgram.com to enable real-time transcription"
        ),
        OnboardingStep(
            title: "Create AI Profiles",
            subtitle: "Process transcripts with different AI models",
            systemImage: "brain",
            description: "Set up profiles with OpenAI, Anthropic, or other LLMs to analyze your recordings"
        ),
        OnboardingStep(
            title: "Ready to Record",
            subtitle: "You're all set!",
            systemImage: "checkmark.circle.fill",
            description: "Start recording and let AI help you capture and process your thoughts"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.blue : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .padding()
            
            // Content
            TabView(selection: $currentStep) {
                StepView(step: steps[0])
                    .tag(0)
                
                StepView(step: steps[1])
                    .tag(1)
                
                StepView(step: steps[2])
                    .tag(2)
                
                StepView(step: steps[3])
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Navigation Buttons
            HStack(spacing: 20) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentStep == steps.count - 1 {
                    Button("Get Started") {
                        showingSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                } else if currentStep == 1 || currentStep == 2 {
                    Button("Configure") {
                        showingSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Skip") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .onDisappear {
                    // After settings, skip to last step
                    currentStep = steps.count - 1
                }
        }
    }
}

struct OnboardingStep {
    let title: String
    let subtitle: String
    let systemImage: String
    let description: String
}

struct StepView: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: step.systemImage)
                .font(.system(size: 100))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse)
            
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(step.subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}