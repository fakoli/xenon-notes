import SwiftUI

struct RecordButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 80, height: 80)
                    .shadow(radius: 4)
                
                if isRecording {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 36, weight: .bold))
                        .transition(.scale)
                } else {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 36, weight: .bold))
                        .transition(.scale)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isRecording)
        .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
    }
}

#Preview {
    RecordButton(isRecording: .constant(false)) {}
}
