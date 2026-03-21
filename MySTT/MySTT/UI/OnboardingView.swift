import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var micPermissionGranted = false
    @State private var accessibilityGranted = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<5) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top)

            Spacer()

            // Step content
            switch currentStep {
            case 0: microphoneStep
            case 1: accessibilityStep
            case 2: hotkeyStep
            case 3: providerStep
            case 4: readyStep
            default: readyStep
            }

            Spacer()

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") { currentStep -= 1 }
                }
                Spacer()
                if currentStep < 4 {
                    Button("Next") { currentStep += 1 }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(30)
        .frame(width: 500, height: 400)
    }

    // MARK: - Step 0: Microphone

    private var microphoneStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("Microphone Access")
                .font(.title2.bold())
            Text("MySTT needs microphone access to capture your speech.")
                .multilineTextAlignment(.center)
            HStack {
                Circle().fill(micPermissionGranted ? .green : .red).frame(width: 8, height: 8)
                Text(micPermissionGranted ? "Granted" : "Not granted")
            }
            Button("Request Permission") {
                Task {
                    micPermissionGranted = await PermissionChecker.requestMicrophonePermission()
                }
            }
        }
    }

    // MARK: - Step 1: Accessibility

    private var accessibilityStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.raised.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Accessibility Permission")
                .font(.title2.bold())
            Text("Required for global hotkey and auto-paste.\nGo to System Settings > Privacy & Security > Accessibility")
                .multilineTextAlignment(.center)
            HStack {
                Circle().fill(accessibilityGranted ? .green : .red).frame(width: 8, height: 8)
                Text(accessibilityGranted ? "Granted" : "Not granted")
            }
            HStack {
                Button("Open Settings") { PermissionChecker.openAccessibilitySettings() }
                Button("Check") { accessibilityGranted = PermissionChecker.checkAccessibilityPermission(prompt: false) }
            }
        }
    }

    // MARK: - Step 2: Hotkey

    private var hotkeyStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 48))
                .foregroundColor(.purple)
            Text("Hotkey Setup")
                .font(.title2.bold())
            Text("Hold the hotkey to record, release to process.\nDefault: Right Option key")
                .multilineTextAlignment(.center)
            Text("\u{2325} Right Option")
                .font(.title3.monospaced())
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).stroke())
        }
    }

    // MARK: - Step 3: Provider

    private var providerStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            Text("LLM Provider")
                .font(.title2.bold())
            Text("Choose how to process your speech.\nLocal = free, offline. Remote = better quality.")
                .multilineTextAlignment(.center)
            VStack(alignment: .leading) {
                Text("Local: MLX (Qwen 2.5 3B) - Free, ~4GB RAM").font(.caption)
                Text("Local: Ollama - Free, requires Ollama app").font(.caption)
                Text("Remote: Grok / Groq / OpenAI - Requires API key").font(.caption)
            }
        }
    }

    // MARK: - Step 4: Ready

    private var readyStep: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            Text("Ready!")
                .font(.title.bold())
            Text("Hold Right Option to start speaking.\nRelease to process and paste.")
                .multilineTextAlignment(.center)
            Button("Start Using MySTT") {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }
}
