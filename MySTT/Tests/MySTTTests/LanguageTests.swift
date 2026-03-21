import XCTest
@testable import MySTT

final class LanguageTests: XCTestCase {
    func test_initFromWhisperCode_english() {
        XCTAssertEqual(Language(whisperCode: "en"), .english)
    }

    func test_initFromWhisperCode_polish() {
        XCTAssertEqual(Language(whisperCode: "pl"), .polish)
    }

    func test_initFromWhisperCode_unknown() {
        XCTAssertEqual(Language(whisperCode: "de"), .unknown)
    }

    func test_initFromWhisperCode_enUS() {
        XCTAssertEqual(Language(whisperCode: "en-US"), .english)
    }

    func test_initFromWhisperCode_plPL() {
        XCTAssertEqual(Language(whisperCode: "pl-PL"), .polish)
    }

    func test_initFromWhisperCode_enGB() {
        XCTAssertEqual(Language(whisperCode: "en-GB"), .english)
    }

    func test_initFromWhisperCode_englishWord() {
        XCTAssertEqual(Language(whisperCode: "english"), .english)
    }

    func test_initFromWhisperCode_polishWord() {
        XCTAssertEqual(Language(whisperCode: "polish"), .polish)
    }

    func test_initFromWhisperCode_caseInsensitive() {
        XCTAssertEqual(Language(whisperCode: "EN"), .english)
        XCTAssertEqual(Language(whisperCode: "PL"), .polish)
    }

    func test_initFromWhisperCode_withWhitespace() {
        XCTAssertEqual(Language(whisperCode: "  en  "), .english)
    }

    func test_displayName_english() {
        XCTAssertEqual(Language.english.displayName, "English")
    }

    func test_displayName_polish() {
        XCTAssertEqual(Language.polish.displayName, "Polski")
    }

    func test_displayName_unknown() {
        XCTAssertEqual(Language.unknown.displayName, "Unknown")
    }

    func test_rawValue() {
        XCTAssertEqual(Language.english.rawValue, "en")
        XCTAssertEqual(Language.polish.rawValue, "pl")
        XCTAssertEqual(Language.unknown.rawValue, "unknown")
    }

    func test_allCases_count() {
        XCTAssertEqual(Language.allCases.count, 3)
    }

    func test_codable_roundtrip() throws {
        let original = Language.english
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Language.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_identifiable_id() {
        XCTAssertEqual(Language.english.id, "en")
        XCTAssertEqual(Language.polish.id, "pl")
    }
}
