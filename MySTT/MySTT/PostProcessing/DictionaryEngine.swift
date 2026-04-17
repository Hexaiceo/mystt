import Foundation

class DictionaryEngine {
    struct DictionaryData: Codable {
        var terms: [String: String]
        var abbreviations: [String: String]
        var polishTerms: [String: String]
        var customWords: [String]
        var rules: [RegexRule]
        var userRules: [String]

        enum CodingKeys: String, CodingKey {
            case terms, abbreviations
            case polishTerms = "polish_terms"
            case customWords = "custom_words"
            case rules
            case userRules = "user_rules"
        }

        init(
            terms: [String: String] = [:],
            abbreviations: [String: String] = [:],
            polishTerms: [String: String] = [:],
            customWords: [String] = [],
            rules: [RegexRule] = [],
            userRules: [String]? = nil
        ) {
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

        static let legacyDefaultUserRules: [String] = [
            "Add proper punctuation: periods, commas, question marks, exclamation marks",
            "Capitalize the first letter of each sentence",
            "Fix obvious spelling mistakes caused by speech recognition errors",
            "Restore Polish diacritical characters where missing (ą, ć, ę, ł, ń, ó, ś, ź, ż)",
            "Do NOT translate to another language — keep the original language",
            "Do NOT rephrase or rewrite sentences — only fix formatting"
        ]

        static let defaultUserRules: [String] = [
            "Do NOT change the language under any circumstances — NEVER translate, localize, or replace English with Polish or Polish with English; keep every word in its original language",
            "Do NOT answer, respond to, or interpret the text — treat it only as dictation to format",
            "Do NOT rephrase or rewrite sentences — only fix formatting and obvious STT typos",
            "Add proper punctuation: periods, commas, question marks, exclamation marks",
            "Capitalize the first letter of each sentence",
            "Fix obvious spelling mistakes caused by speech recognition errors",
            "Restore Polish diacritical characters where missing (ą, ć, ę, ł, ń, ó, ś, ź, ż)"
        ]
    }

    struct RegexRule: Codable {
        let pattern: String
        let replacement: String
    }

    struct ProtectedTermsPlan {
        let protectedText: String
        fileprivate let placeholderOrder: [String]
        fileprivate let placeholderToTerm: [String: String]

        static func passthrough(_ text: String) -> ProtectedTermsPlan {
            ProtectedTermsPlan(protectedText: text, placeholderOrder: [], placeholderToTerm: [:])
        }

        var isEmpty: Bool { placeholderOrder.isEmpty }
        var placeholders: [String] { placeholderOrder }
    }

    private struct PhraseEntry {
        let source: String
        let normalizedTokens: [String]
        let replacement: String
    }

    private struct WordToken {
        let text: String
        let normalized: String
        let range: Range<String.Index>
    }

    private struct PlannedMatch {
        let wordRange: Range<Int>
        let textRange: Range<String.Index>
        let replacement: String
    }

    private var data: DictionaryData
    private let userDictionaryPath: String
    private let normalizationLocale = Locale(identifier: "en_US_POSIX")

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
            migrateLegacyDefaultUserRulesIfNeeded()
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

    private func migrateLegacyDefaultUserRulesIfNeeded() {
        guard data.userRules == DictionaryData.legacyDefaultUserRules else { return }
        data.userRules = DictionaryData.defaultUserRules
        saveDictionary()
    }

    func saveDictionary() {
        let dir = (userDictionaryPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if let jsonData = try? JSONEncoder().encode(data) {
            try? jsonData.write(to: URL(fileURLWithPath: userDictionaryPath))
        }
    }

    func preProcess(_ text: String) -> String {
        applyTermReplacements(to: text)
    }

    func postProcess(_ text: String) -> String {
        var result = applyTermReplacements(to: text)
        for rule in data.rules {
            if let regex = try? NSRegularExpression(pattern: rule.pattern) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: rule.replacement
                )
            }
        }
        return result
    }

    func applyTermReplacements(to text: String) -> String {
        replacePhrases(in: text, entries: replacementEntries())
    }

    func protectCanonicalTerms(in text: String) -> ProtectedTermsPlan {
        let phrases = canonicalProtectedPhrases()
        guard !phrases.isEmpty else { return .passthrough(text) }

        let entries = phrases.compactMap { phrase -> PhraseEntry? in
            let normalizedTokens = normalizePhraseTokens(phrase)
            guard !normalizedTokens.isEmpty else { return nil }
            return PhraseEntry(source: phrase, normalizedTokens: normalizedTokens, replacement: phrase)
        }

        let matches = plannedMatches(in: text, entries: entries)
        guard !matches.isEmpty else { return .passthrough(text) }

        var replacements: [String] = []
        var placeholderToTerm: [String: String] = [:]
        var transformed = ""
        var cursor = text.startIndex

        for (index, match) in matches.enumerated() {
            transformed += text[cursor..<match.textRange.lowerBound]
            let placeholder = "MYSTTTERM\(index)TOKEN"
            transformed += placeholder
            cursor = match.textRange.upperBound
            replacements.append(placeholder)
            placeholderToTerm[placeholder] = match.replacement
        }

        transformed += text[cursor...]
        return ProtectedTermsPlan(
            protectedText: transformed,
            placeholderOrder: replacements,
            placeholderToTerm: placeholderToTerm
        )
    }

    func restoreProtectedTerms(in text: String, using plan: ProtectedTermsPlan) -> String {
        guard !plan.isEmpty else { return text }

        var result = text
        for placeholder in plan.placeholderOrder {
            guard let replacement = plan.placeholderToTerm[placeholder] else { continue }
            result = result.replacingOccurrences(of: placeholder, with: replacement)
        }
        return result
    }

    func placeholdersPreserved(in output: String, plan: ProtectedTermsPlan) -> Bool {
        guard !plan.isEmpty else { return true }
        return plan.placeholders.allSatisfy { occurrences(of: $0, in: output) == 1 }
    }

    func buildSTTPrompt(maxCharacters: Int = 240) -> String? {
        let candidates = canonicalProtectedPhrases()
        guard !candidates.isEmpty else { return nil }

        var prompt = "Use exact spellings for: "
        var appended: [String] = []

        for candidate in candidates {
            let nextList = (appended + [candidate]).joined(separator: ", ")
            let nextPrompt = "Use exact spellings for: \(nextList)"
            if nextPrompt.count > maxCharacters {
                break
            }
            appended.append(candidate)
            prompt = nextPrompt
        }

        return appended.isEmpty ? nil : prompt
    }

    // MARK: - Terms CRUD

    func addTerm(key: String, value: String) {
        data.terms[key] = value
        saveDictionary()
    }

    func removeTerm(key: String) {
        data.terms.removeValue(forKey: key)
        saveDictionary()
    }

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

    func getDictionaryTermsForPrompt() -> String {
        var parts: [String] = []

        let allTerms = getAllTerms()
        if !allTerms.isEmpty {
            let renderedTerms = allTerms
                .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
                .map { "\($0.key)->\($0.value)" }
                .joined(separator: ", ")
            parts.append(renderedTerms)
        }

        if !data.customWords.isEmpty {
            let renderedWords = data.customWords.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            parts.append("Keep exact spelling: \(renderedWords.joined(separator: ", "))")
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

    func getUserRulesForPrompt() -> String {
        guard !data.userRules.isEmpty else { return "" }
        if data.userRules == DictionaryData.defaultUserRules { return "" }
        return data.userRules.joined(separator: ". ")
    }

    // MARK: - Properties

    var terms: [String: String] { data.terms }
    var polishTerms: [String: String] { data.polishTerms }
    var abbreviations: [String: String] { data.abbreviations }
    var customWords: [String] { data.customWords }
    var userRules: [String] { data.userRules }

    // MARK: - Matching

    private func replacementEntries() -> [PhraseEntry] {
        getAllTerms().compactMap { key, value in
            let normalizedTokens = normalizePhraseTokens(key)
            guard !normalizedTokens.isEmpty else { return nil }
            return PhraseEntry(source: key, normalizedTokens: normalizedTokens, replacement: value)
        }
    }

    private func canonicalProtectedPhrases() -> [String] {
        let merged = Set(getAllTerms().values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } + data.customWords)
        return merged
            .filter { !$0.isEmpty }
            .sorted { lhs, rhs in
                let lhsTokens = normalizePhraseTokens(lhs).count
                let rhsTokens = normalizePhraseTokens(rhs).count
                if lhsTokens != rhsTokens { return lhsTokens > rhsTokens }
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
            }
    }

    private func replacePhrases(in text: String, entries: [PhraseEntry]) -> String {
        let matches = plannedMatches(in: text, entries: entries)
        guard !matches.isEmpty else { return text }

        var result = ""
        var cursor = text.startIndex

        for match in matches {
            result += text[cursor..<match.textRange.lowerBound]
            result += match.replacement
            cursor = match.textRange.upperBound
        }

        result += text[cursor...]
        return result
    }

    private func plannedMatches(in text: String, entries: [PhraseEntry]) -> [PlannedMatch] {
        let tokens = wordTokens(in: text)
        guard !tokens.isEmpty, !entries.isEmpty else { return [] }

        let orderedEntries = entries.sorted { lhs, rhs in
            if lhs.normalizedTokens.count != rhs.normalizedTokens.count {
                return lhs.normalizedTokens.count > rhs.normalizedTokens.count
            }
            if lhs.source.count != rhs.source.count {
                return lhs.source.count > rhs.source.count
            }
            return lhs.source.localizedCaseInsensitiveCompare(rhs.source) == .orderedAscending
        }

        var matches: [PlannedMatch] = []
        var occupiedWordIndexes = Set<Int>()

        for entry in orderedEntries {
            let phraseLength = entry.normalizedTokens.count
            guard phraseLength > 0, tokens.count >= phraseLength else { continue }

            var index = 0
            while index <= tokens.count - phraseLength {
                let candidateRange = index..<(index + phraseLength)

                if candidateRange.contains(where: { occupiedWordIndexes.contains($0) }) {
                    index += 1
                    continue
                }

                let candidateTokens = tokens[candidateRange].map(\.normalized)
                if candidateTokens == entry.normalizedTokens {
                    let textRange = tokens[index].range.lowerBound..<tokens[index + phraseLength - 1].range.upperBound
                    matches.append(PlannedMatch(wordRange: candidateRange, textRange: textRange, replacement: entry.replacement))
                    occupiedWordIndexes.formUnion(candidateRange)
                    index += phraseLength
                } else {
                    index += 1
                }
            }
        }

        return matches.sorted { $0.textRange.lowerBound < $1.textRange.lowerBound }
    }

    private func normalizePhraseTokens(_ phrase: String) -> [String] {
        wordTokens(in: phrase).map(\.normalized)
    }

    private func wordTokens(in text: String) -> [WordToken] {
        var tokens: [WordToken] = []
        var index = text.startIndex

        while index < text.endIndex {
            guard isTokenStart(text[index]) else {
                index = text.index(after: index)
                continue
            }

            let start = index
            var end = text.index(after: index)
            while end < text.endIndex, isTokenContinuation(text[end]) {
                end = text.index(after: end)
            }

            let token = String(text[start..<end])
            let normalized = normalizeToken(token)
            if !normalized.isEmpty {
                tokens.append(WordToken(text: token, normalized: normalized, range: start..<end))
            }
            index = end
        }

        return tokens
    }

    private func normalizeToken(_ token: String) -> String {
        let folded = token.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: normalizationLocale)
        let filtered = folded.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "+" || scalar == "#"
        }
        return String(String.UnicodeScalarView(filtered))
    }

    private func isTokenStart(_ character: Character) -> Bool {
        character.unicodeScalars.contains { CharacterSet.alphanumerics.contains($0) }
    }

    private func isTokenContinuation(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            CharacterSet.alphanumerics.contains(scalar) ||
            scalar == "'" ||
            scalar == "." ||
            scalar == "_" ||
            scalar == "-" ||
            scalar == "+" ||
            scalar == "#"
        }
    }

    private func occurrences(of needle: String, in haystack: String) -> Int {
        guard !needle.isEmpty else { return 0 }

        var count = 0
        var searchRange = haystack.startIndex..<haystack.endIndex

        while let found = haystack.range(of: needle, options: [], range: searchRange) {
            count += 1
            searchRange = found.upperBound..<haystack.endIndex
        }

        return count
    }
}
