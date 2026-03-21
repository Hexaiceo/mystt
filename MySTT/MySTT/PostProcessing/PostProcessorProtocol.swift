import Foundation

protocol PostProcessorProtocol {
    func process(_ rawText: String, language: Language) async throws -> String
}
