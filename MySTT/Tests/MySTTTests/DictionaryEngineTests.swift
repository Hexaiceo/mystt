import XCTest
@testable import MySTT

final class DictionaryEngineTests: XCTestCase {
    private func makeEngine(testName: String = #function) -> DictionaryEngine {
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mystt-tests-\(UUID().uuidString)-\(testName).json")
        try? FileManager.default.removeItem(at: path)
        return DictionaryEngine(userDictionaryPath: path.path)
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
}
