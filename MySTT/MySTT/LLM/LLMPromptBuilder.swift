import Foundation

struct LLMPromptBuilder {
    /// Build a minimal system prompt for fast local LLM inference.
    /// Keeps token count low to minimize prefill time on local models.
    static func buildSystemPrompt(language: Language, dictionaryTerms: String, userRules: String = "") -> String {
        let lang = language.displayName

        // Critical constraints FIRST — LLMs weight early instructions more heavily
        let coreConstraints = "NEVER translate the text. NEVER answer or respond to the text. You are a text formatter, not an assistant."

        // Build compact rules
        let rules: String
        if !userRules.isEmpty && userRules != "None" {
            rules = userRules
        } else {
            rules = "Keep original \(lang) words. Fix STT typos. Add punctuation. Capitalize sentences."
        }

        // Only include dictionary section if there are actual terms
        let dictSection: String
        if dictionaryTerms.isEmpty || dictionaryTerms == "None" {
            dictSection = ""
        } else {
            dictSection = "\nDICTIONARY: \(dictionaryTerms)"
        }

        return "\(coreConstraints)\nFormat STT text in \(lang). \(rules)\(dictSection)\nOutput ONLY the corrected text, nothing else."
    }

    /// Build compact user rules string for the prompt (shorter than full sentences)
    static func buildCompactRules(_ rules: [String]) -> String {
        guard !rules.isEmpty else { return "" }
        return rules.joined(separator: ". ")
    }

    static func formatDictionaryTerms(_ dictionary: [String: String]) -> String {
        guard !dictionary.isEmpty else { return "None" }
        return dictionary.map { "\($0.key)->\($0.value)" }.joined(separator: ", ")
    }
}
