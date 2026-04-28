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
        XCTAssertEqual(Language.polish.displayName, "Polish")
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

    func test_postProcessor_detectTextLanguage_commandWithFilename_isEnglish() {
        XCTAssertEqual(PostProcessor.detectTextLanguage("answer in q2.html"), .english)
    }

    func test_whisperLooksLikeEnglish_commandWithFilename() {
        XCTAssertTrue(WhisperKitEngine.looksLikeEnglish("answer in q2.html"))
    }

    func test_postProcessor_detectTextLanguage_shortEnglishPhrase() {
        XCTAssertEqual(PostProcessor.detectTextLanguage("Hey Jihed, sure."), .english)
    }

    func test_postProcessor_detectTextLanguage_nowItSeemsOk_isEnglish() {
        XCTAssertEqual(PostProcessor.detectTextLanguage("now it seems ok"), .english)
    }

    func test_postProcessor_detectTextLanguage_shortPolishPhrase() {
        XCTAssertEqual(PostProcessor.detectTextLanguage("Hej Jihed, pewnie."), .polish)
    }

    func test_postProcessor_detectTextLanguage_polishWithoutDiacritics_isPolish() {
        XCTAssertEqual(PostProcessor.detectTextLanguage("to wyglada dobrze"), .polish)
    }

    func test_postProcessor_detectTextLanguage_polishNoToOk_isPolish() {
        XCTAssertEqual(PostProcessor.detectTextLanguage("no to jest ok"), .polish)
    }

    func test_postProcessor_detectTextLanguage_polishParticleNo_isAmbiguous() {
        XCTAssertEqual(PostProcessor.detectTextLanguage("no"), .unknown)
    }

    func test_whisperPrefersEnglishCandidateForShortEnglishUtterance() {
        let preferred = WhisperKitEngine.preferredForcedLanguage(
            polishText: "Hej Cihat, pewnie.",
            englishText: "Hey Jihed, sure.",
            polishAverageLogProb: -1.1,
            englishAverageLogProb: -0.2
        )

        XCTAssertEqual(preferred, .english)
    }

    func test_whisperPrefersPolishCandidateForShortPolishUtterance() {
        let preferred = WhisperKitEngine.preferredForcedLanguage(
            polishText: "Hej Jihed, pewnie.",
            englishText: "Hey Jihed, sure.",
            polishAverageLogProb: -0.2,
            englishAverageLogProb: -1.0
        )

        XCTAssertEqual(preferred, .polish)
    }

    func test_whisperPrefersEnglishCandidateForNowItSeemsOk() {
        let preferred = WhisperKitEngine.preferredForcedLanguage(
            polishText: "Teraz wygląda ok.",
            englishText: "Now it seems ok.",
            polishAverageLogProb: -0.35,
            englishAverageLogProb: -0.55,
            detectedSpokenLanguage: .english
        )

        XCTAssertEqual(preferred, .english)
    }

    func test_whisperPrefersPolishCandidateForNoDiacriticsPolishUtterance() {
        let preferred = WhisperKitEngine.preferredForcedLanguage(
            polishText: "To wyglada dobrze.",
            englishText: "It looks good.",
            polishAverageLogProb: -0.55,
            englishAverageLogProb: -0.35,
            detectedSpokenLanguage: .polish
        )

        XCTAssertEqual(preferred, .polish)
    }

    // MARK: - Cross-candidate translation detection

    func test_whisperPrefersPolishWhenEnglishIsTranslation() {
        let preferred = WhisperKitEngine.preferredForcedLanguage(
            polishText: "Teraz to wygląda dobrze.",
            englishText: "Now it looks good.",
            polishAverageLogProb: -0.7,
            englishAverageLogProb: -0.3
        )
        XCTAssertEqual(preferred, .polish)
    }

    func test_whisperPrefersPolishWhenEnglishIsTranslation_noSpokenPrior() {
        let preferred = WhisperKitEngine.preferredForcedLanguage(
            polishText: "Sprawdzmy czy to działa poprawnie.",
            englishText: "Let's check if it works correctly.",
            polishAverageLogProb: -0.8,
            englishAverageLogProb: -0.25
        )
        XCTAssertEqual(preferred, .polish)
    }

    func test_whisperPrefersPolishWhenEnglishIsTranslation_strongLogProbBias() {
        let preferred = WhisperKitEngine.preferredForcedLanguage(
            polishText: "Muszę to naprawić jak najszybciej.",
            englishText: "I need to fix this as soon as possible.",
            polishAverageLogProb: -1.0,
            englishAverageLogProb: -0.2
        )
        XCTAssertEqual(preferred, .polish)
    }

    func test_whisperPrefersEnglishWhenBothCandidatesAreEnglish() {
        let preferred = WhisperKitEngine.preferredForcedLanguage(
            polishText: "Hello, how are you?",
            englishText: "Hello, how are you?",
            polishAverageLogProb: -0.5,
            englishAverageLogProb: -0.3
        )
        XCTAssertEqual(preferred, .english)
    }

    func test_crossCandidateAnalysis_translationPair() {
        let result = WhisperKitEngine.crossCandidateAnalysis(
            polishText: "To wyglada dobrze.",
            englishText: "It looks good."
        )
        XCTAssertTrue(result.isTranslationPair)
        XCTAssertFalse(result.isSameContent)
    }

    func test_crossCandidateAnalysis_sameContent() {
        let result = WhisperKitEngine.crossCandidateAnalysis(
            polishText: "Hello world.",
            englishText: "Hello world."
        )
        XCTAssertFalse(result.isTranslationPair)
        XCTAssertTrue(result.isSameContent)
    }

    func test_crossCandidateAnalysis_sameContentWithDiacritics() {
        let result = WhisperKitEngine.crossCandidateAnalysis(
            polishText: "Jihed córka",
            englishText: "Jihed corka"
        )
        XCTAssertFalse(result.isTranslationPair)
        XCTAssertTrue(result.isSameContent)
    }
}
