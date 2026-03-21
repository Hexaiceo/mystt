import Foundation

struct LLMPromptBuilder {
    /// Build a minimal system prompt for fast local LLM inference.
    /// Keeps token count low to minimize prefill time on local models.
    static func buildSystemPrompt(language: Language, dictionaryTerms: String, userRules: String = "") -> String {
        let lang = language.displayName

        // Build compact rules
        let rules: String
        if !userRules.isEmpty && userRules != "None" {
            rules = userRules
        } else {
            rules = "Add punctuation. Capitalize sentences. Fix STT typos. Keep original \(lang) words. NEVER rephrase, rewrite, or change meaning."
        }

        // Only include dictionary section if there are actual terms
        let dictSection: String
        if dictionaryTerms.isEmpty || dictionaryTerms == "None" {
            dictSection = ""
        } else {
            dictSection = "\nDICTIONARY: \(dictionaryTerms)"
        }

        return "Format STT text in \(lang). \(rules)\(dictSection)\nOutput ONLY the corrected text, nothing else."
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
