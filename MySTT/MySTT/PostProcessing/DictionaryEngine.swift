import Foundation

class DictionaryEngine {
    struct DictionaryData: Codable {
        var terms: [String: String]
        var abbreviations: [String: String]
        var polishTerms: [String: String]
        var customWords: [String]
        var rules: [RegexRule]
        var userRules: [String]  // LLM transformation rules (user-defined guardrails)

        enum CodingKeys: String, CodingKey {
            case terms, abbreviations
            case polishTerms = "polish_terms"
            case customWords = "custom_words"
            case rules
            case userRules = "user_rules"
        }

        init(terms: [String: String] = [:], abbreviations: [String: String] = [:],
             polishTerms: [String: String] = [:], customWords: [String] = [],
             rules: [RegexRule] = [], userRules: [String]? = nil) {
            self.terms = terms
            self.abbreviations = abbreviations
            self.polishTerms = polishTerms
            self.customWords = customWords
            self.rules = rules
            self.userRules = userRules ?? Self.defaultUserRules
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            terms = try container.decodeIfPresent([String: String].self, forKey: .terms) ?? [:]
            abbreviations = try container.decodeIfPresent([String: String].self, forKey: .abbreviations) ?? [:]
            polishTerms = try container.decodeIfPresent([String: String].self, forKey: .polishTerms) ?? [:]
            customWords = try container.decodeIfPresent([String].self, forKey: .customWords) ?? []
            rules = try container.decodeIfPresent([RegexRule].self, forKey: .rules) ?? []
            userRules = try container.decodeIfPresent([String].self, forKey: .userRules) ?? Self.defaultUserRules
        }

        static let defaultUserRules: [String] = [
            "NEVER translate — keep the original language exactly as spoken",
            "NEVER answer, respond to, or interpret the text — only correct formatting",
            "Do NOT rephrase or rewrite sentences — only fix formatting and typos",
            "Add proper punctuation: periods, commas, question marks, exclamation marks",
            "Capitalize the first letter of each sentence",
            "Fix obvious spelling mistakes caused by speech recognition errors",
            "Restore Polish diacritical characters where missing (ą, ć, ę, ł, ń, ó, ś, ź, ż)",
        ]
    }

    struct RegexRule: Codable {
        let pattern: String
        let replacement: String
    }

    private var data: DictionaryData
    private let userDictionaryPath: String

    init(userDictionaryPath: String? = nil) {
        self.userDictionaryPath = userDictionaryPath ?? (NSHomeDirectory() + "/.mystt/dictionary.json")
        self.data = DictionaryData()
        loadDictionary()
    }

    func loadDictionary() {
        if FileManager.default.fileExists(atPath: userDictionaryPath),
           let jsonData = try? Data(contentsOf: URL(fileURLWithPath: userDictionaryPath)),
           let decoded = try? JSONDecoder().decode(DictionaryData.self, from: jsonData) {
            data = decoded
            return
        }
        if let url = Bundle.main.url(forResource: "default_dictionary", withExtension: "json"),
           let jsonData = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(DictionaryData.self, from: jsonData) {
            data = decoded
            return
        }
        data = DictionaryData(rules: [
            RegexRule(pattern: "\\s+([.,!?;:])", replacement: "$1"),
            RegexRule(pattern: "\\s{2,}", replacement: " ")
        ])
    }

    func saveDictionary() {
        let dir = (userDictionaryPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if let jsonData = try? JSONEncoder().encode(data) {
            try? jsonData.write(to: URL(fileURLWithPath: userDictionaryPath))
        }
    }

    func preProcess(_ text: String) -> String {
        var result = text
        let allTerms = data.terms.merging(data.polishTerms) { current, _ in current }
        for (key, value) in allTerms {
            result = result.replacingOccurrences(of: key, with: value, options: .caseInsensitive)
        }
        return result
    }

    func postProcess(_ text: String) -> String {
        var result = text
        for rule in data.rules {
            if let regex = try? NSRegularExpression(pattern: rule.pattern) {
                result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: rule.replacement)
            }
        }
        return result
    }

    // MARK: - Terms CRUD

    func addTerm(key: String, value: String) { data.terms[key] = value; saveDictionary() }
    func removeTerm(key: String) { data.terms.removeValue(forKey: key); saveDictionary() }

    // MARK: - Custom Words CRUD

    func addCustomWord(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !data.customWords.contains(trimmed) else { return }
        data.customWords.append(trimmed)
        saveDictionary()
    }

    func removeCustomWord(_ word: String) {
        data.customWords.removeAll { $0 == word }
        saveDictionary()
    }

    func removeAllCustomWords() {
        data.customWords.removeAll()
        saveDictionary()
    }

    // MARK: - For LLM Prompt

    func getAllTerms() -> [String: String] {
        data.terms.merging(data.polishTerms) { current, _ in current }
    }

    /// Returns compact formatted string for LLM system prompt including terms AND custom words
    func getDictionaryTermsForPrompt() -> String {
        var parts: [String] = []

        let allTerms = getAllTerms()
        if !allTerms.isEmpty {
            parts.append(allTerms.map { "\($0.key)->\($0.value)" }.joined(separator: ", "))
        }

        if !data.customWords.isEmpty {
            parts.append("Keep exact spelling: \(data.customWords.joined(separator: ", "))")
        }

        return parts.isEmpty ? "None" : parts.joined(separator: ". ")
    }

    // MARK: - User Rules CRUD

    func addUserRule(_ rule: String) {
        let trimmed = rule.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !data.userRules.contains(trimmed) else { return }
        data.userRules.append(trimmed)
        saveDictionary()
    }

    func removeUserRule(at index: Int) {
        guard index >= 0, index < data.userRules.count else { return }
        data.userRules.remove(at: index)
        saveDictionary()
    }

    func resetUserRulesToDefaults() {
        data.userRules = DictionaryData.defaultUserRules
        saveDictionary()
    }

    /// Returns the user rules formatted compactly for the LLM system prompt.
    /// Returns empty string when using defaults, so the prompt builder uses its own ultra-compact version.
    func getUserRulesForPrompt() -> String {
        guard !data.userRules.isEmpty else { return "" }
        // If rules match defaults, return empty to let prompt builder use its compact built-in rules
        if data.userRules == DictionaryData.defaultUserRules { return "" }
        // Custom rules: make compact
        return data.userRules.joined(separator: ". ")
    }

    // MARK: - Properties

    var terms: [String: String] { data.terms }
    var polishTerms: [String: String] { data.polishTerms }
    var abbreviations: [String: String] { data.abbreviations }
    var customWords: [String] { data.customWords }
    var userRules: [String] { data.userRules }
}
