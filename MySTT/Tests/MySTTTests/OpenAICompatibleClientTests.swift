import XCTest
@testable import MySTT

final class OpenAICompatibleClientTests: XCTestCase {
    func test_requestSizing_scalesUpForLongDictation() {
        let short = OpenAICompatibleClient.requestSizing(
            for: "Short transcript.",
            defaultTimeout: 10
        )
        let longTranscript = String(repeating: "This is a much longer dictated transcript segment. ", count: 120)
        let long = OpenAICompatibleClient.requestSizing(
            for: longTranscript,
            defaultTimeout: 10
        )

        XCTAssertGreaterThan(long.maxTokens, short.maxTokens)
        XCTAssertGreaterThan(long.timeout, short.timeout)
        XCTAssertLessThanOrEqual(long.maxTokens, 1536)
        XCTAssertLessThanOrEqual(long.timeout, 180)
    }

    func test_requestSizing_respectsExplicitMaxTokens() {
        let sizing = OpenAICompatibleClient.requestSizing(
            for: "whatever",
            explicitMaxTokens: 321,
            defaultTimeout: 17
        )

        XCTAssertEqual(sizing.maxTokens, 321)
        XCTAssertEqual(sizing.timeout, 17)
    }
}
