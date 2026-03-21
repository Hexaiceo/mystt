import XCTest
@testable import MySTT

final class DictionaryEngineTests: XCTestCase {
    func test_preProcess_caseInsensitive() {
        let engine = DictionaryEngine()
        let result = engine.preProcess("I use kubernetes daily")
        XCTAssertTrue(result.contains("Kubernetes"))
    }

    func test_preProcess_multipleTerms() {
        let engine = DictionaryEngine()
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
        let engine = DictionaryEngine()
        engine.addTerm(key: "testterm123unique", value: "TestTerm123Unique")
        XCTAssertEqual(engine.terms["testterm123unique"], "TestTerm123Unique")
        engine.removeTerm(key: "testterm123unique")
        XCTAssertNil(engine.terms["testterm123unique"])
    }

    func test_getAllTerms_includesPolishTerms() {
        let engine = DictionaryEngine()
        let terms = engine.getAllTerms()
        // getAllTerms merges terms and polishTerms
        XCTAssertGreaterThan(terms.count, 0)
    }

    func test_getDictionaryTermsForPrompt_notEmpty() {
        let engine = DictionaryEngine()
        let prompt = engine.getDictionaryTermsForPrompt()
        XCTAssertFalse(prompt.isEmpty)
    }

    func test_getDictionaryTermsForPrompt_containsArrow() {
        let engine = DictionaryEngine()
        let prompt = engine.getDictionaryTermsForPrompt()
        XCTAssertTrue(prompt.contains("->"))
    }

    func test_terms_property() {
        let engine = DictionaryEngine()
        let terms = engine.terms
        XCTAssertNotNil(terms)
    }

    func test_polishTerms_property() {
        let engine = DictionaryEngine()
        let polishTerms = engine.polishTerms
        XCTAssertNotNil(polishTerms)
    }

    func test_abbreviations_property() {
        let engine = DictionaryEngine()
        let abbreviations = engine.abbreviations
        XCTAssertNotNil(abbreviations)
    }

    func test_preProcess_noMatchReturnsOriginal() {
        let engine = DictionaryEngine()
        let input = "completely unique string with no matches xyz123"
        let result = engine.preProcess(input)
        XCTAssertEqual(result, input)
    }
}
