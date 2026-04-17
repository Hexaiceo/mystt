import XCTest
@testable import MySTT

final class DictionaryEngineTests: XCTestCase {
    private func makeEngine(testName: String = #function) -> DictionaryEngine {
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mystt-tests-\(UUID().uuidString)-\(testName).json")
        try? FileManager.default.removeItem(at: path)
        return DictionaryEngine(userDictionaryPath: path.path)
    }

    private func makeLegacyRulesFile(testName: String = #function) throws -> String {
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mystt-legacy-rules-\(UUID().uuidString)-\(testName).json")
        let payload: [String: Any] = [
            "terms": [:],
            "abbreviations": [:],
            "polish_terms": [:],
            "custom_words": [],
            "rules": [],
            "user_rules": DictionaryEngine.DictionaryData.legacyDefaultUserRules
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        try data.write(to: path)
        return path.path
    }

    func test_preProcess_caseInsensitive() {
        let engine = makeEngine()
        engine.addTerm(key: "testterm", value: "TestTerm")

        let result = engine.preProcess("I use TESTTERM daily")

        XCTAssertTrue(result.contains("TestTerm"))
    }

    func test_preProcess_multipleTerms() {
        let engine = makeEngine()
        engine.addTerm(key: "react", value: "React")
        engine.addTerm(key: "typescript", value: "TypeScript")

        let result = engine.preProcess("I use react and typescript")

        XCTAssertTrue(result.contains("React"))
        XCTAssertTrue(result.contains("TypeScript"))
    }

    func test_preProcess_doesNotReplaceInsideLargerWord() {
        let engine = makeEngine()
        engine.addTerm(key: "react", value: "React")

        let result = engine.preProcess("preact is different from react")

        XCTAssertEqual(result, "preact is different from React")
    }

    func test_preProcess_matchesIgnoringDiacritics() {
        let engine = makeEngine()
        engine.addTerm(key: "swiecie", value: "świecie")

        let result = engine.preProcess("witaj świecie")

        XCTAssertEqual(result, "witaj świecie")
    }

    func test_preProcess_matchesMultiWordPhrase() {
        let engine = makeEngine()
        engine.addTerm(key: "machine learning", value: "Machine Learning")

        let result = engine.preProcess("i like machine learning projects")

        XCTAssertEqual(result, "i like Machine Learning projects")
    }

    func test_postProcess_doubleSpaces() {
        let engine = DictionaryEngine()
        let result = engine.postProcess("hello  world")
        XCTAssertFalse(result.contains("  "))
    }

    func test_postProcess_spaceBeforePunctuation() {
        let engine = DictionaryEngine()
        let result = engine.postProcess("hello , world")
        XCTAssertEqual(result, "hello, world")
    }

    func test_addAndRemoveTerm() {
        let engine = makeEngine()
        engine.addTerm(key: "testterm123unique", value: "TestTerm123Unique")
        XCTAssertEqual(engine.terms["testterm123unique"], "TestTerm123Unique")
        engine.removeTerm(key: "testterm123unique")
        XCTAssertNil(engine.terms["testterm123unique"])
    }

    func test_getAllTerms_includesPolishTerms() {
        let engine = makeEngine()
        engine.addTerm(key: "customterm", value: "CustomTerm")
        let terms = engine.getAllTerms()
        XCTAssertEqual(terms["customterm"], "CustomTerm")
    }

    func test_getDictionaryTermsForPrompt_notEmpty() {
        let engine = makeEngine()
        engine.addTerm(key: "promptkey", value: "PromptValue")
        let prompt = engine.getDictionaryTermsForPrompt()
        XCTAssertFalse(prompt.isEmpty)
    }

    func test_getDictionaryTermsForPrompt_containsArrow() {
        let engine = makeEngine()
        engine.addTerm(key: "arrowkey", value: "ArrowValue")
        let prompt = engine.getDictionaryTermsForPrompt()
        XCTAssertTrue(prompt.contains("->"))
    }

    func test_terms_property() {
        let engine = makeEngine()
        let terms = engine.terms
        XCTAssertNotNil(terms)
    }

    func test_polishTerms_property() {
        let engine = makeEngine()
        let polishTerms = engine.polishTerms
        XCTAssertNotNil(polishTerms)
    }

    func test_abbreviations_property() {
        let engine = makeEngine()
        let abbreviations = engine.abbreviations
        XCTAssertNotNil(abbreviations)
    }

    func test_preProcess_noMatchReturnsOriginal() {
        let engine = makeEngine()
        let input = "completely unique string with no matches xyz123"
        let result = engine.preProcess(input)
        XCTAssertEqual(result, input)
    }

    func test_defaultUserRules_putLanguageFirst() {
        let engine = makeEngine()

        XCTAssertEqual(engine.userRules.first, DictionaryEngine.DictionaryData.defaultUserRules.first)
        XCTAssertTrue(engine.userRules.first?.contains("Do NOT change the language") ?? false)
    }

    func test_loadDictionary_migratesLegacyDefaultUserRules() throws {
        let path = try makeLegacyRulesFile()

        let engine = DictionaryEngine(userDictionaryPath: path)

        XCTAssertEqual(engine.userRules, DictionaryEngine.DictionaryData.defaultUserRules)
    }

    func test_protectCanonicalTerms_roundTripsCustomWords() {
        let engine = makeEngine()
        engine.addCustomWord("Jihed")
        engine.addTerm(key: "mac os", value: "macOS")

        let plan = engine.protectCanonicalTerms(in: "Jihed uses macOS daily")
        let restored = engine.restoreProtectedTerms(in: plan.protectedText, using: plan)

        XCTAssertNotEqual(plan.protectedText, "Jihed uses macOS daily")
        XCTAssertEqual(restored, "Jihed uses macOS daily")
        XCTAssertTrue(engine.placeholdersPreserved(in: plan.protectedText, plan: plan))
    }

    func test_buildSTTPrompt_usesCanonicalSpellings() {
        let engine = makeEngine()
        engine.addTerm(key: "mac os", value: "macOS")
        engine.addCustomWord("Jihed")

        let prompt = engine.buildSTTPrompt()

        XCTAssertTrue(prompt?.contains("macOS") ?? false)
        XCTAssertTrue(prompt?.contains("Jihed") ?? false)
        XCTAssertFalse(prompt?.contains("mac os") ?? true)
    }
}
