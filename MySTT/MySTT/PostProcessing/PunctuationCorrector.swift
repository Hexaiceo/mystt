import Foundation

class PunctuationCorrector {
    private let pythonPath: String
    private let scriptPath: String
    private let timeout: TimeInterval

    init(pythonPath: String = "/usr/bin/python3", timeout: TimeInterval = 10) {
        self.pythonPath = pythonPath
        let bundle = Bundle.main.resourcePath ?? "."
        self.scriptPath = "\(bundle)/Scripts/punctuation_correct.py"
        self.timeout = timeout
    }

    func correct(_ text: String, language: Language) async throws -> String {
        let prefix = language == .polish ? "<pl>" : "<en>"
        let input = "\(prefix) \(text)"

        // Check if Python is available
        guard FileManager.default.fileExists(atPath: pythonPath) else {
            print("[PunctuationCorrector] Python not found at \(pythonPath), returning text unchanged")
            return text
        }

        // Check if script exists
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            print("[PunctuationCorrector] Script not found at \(scriptPath), returning text unchanged")
            return text
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: self.pythonPath)
                process.arguments = [self.scriptPath, input]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                    if process.terminationStatus == 0 && !output.isEmpty {
                        continuation.resume(returning: output)
                    } else {
                        // Fallback: return text unchanged
                        continuation.resume(returning: text)
                    }
                } catch {
                    continuation.resume(returning: text) // Fallback
                }
            }
        }
    }
}
