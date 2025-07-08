import SwiftUI

struct RecordButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.regularMaterial.opacity(0.8))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 72, height: 72)
                    )
                
                if isRecording {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 36, weight: .bold))
                        .transition(.scale)
                } else {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 36, weight: .bold))
                        .transition(.scale)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isRecording)
        .animation(.spring(response: 0.1, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .hoverEffect(.automatic)
        .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
    }
}

#Preview {
    RecordButton(isRecording: .constant(false)) {}
}
