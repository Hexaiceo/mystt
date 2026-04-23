import Foundation
import XCTest
@testable import MySTT

private final class MockURLProtocol: URLProtocol {
    typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    private static var handlers: [RequestHandler] = []
    private static var recordedRequests: [URLRequest] = []

    static func configure(handlers: [RequestHandler]) {
        lock.lock()
        self.handlers = handlers
        recordedRequests = []
        lock.unlock()
    }

    static func requests() -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return recordedRequests
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.recordedRequests.append(request)
        let handler = Self.handlers.isEmpty ? nil : Self.handlers.removeFirst()
        Self.lock.unlock()

        guard let handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class OpenAICompatibleClientTests: XCTestCase {
    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func requestBody(from request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            throw XCTSkip("Request body was not available on the captured request")
        }

        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                break
            }
            if read == 0 {
                break
            }
            data.append(buffer, count: read)
        }

        return data
    }

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

    func test_normalizedBaseURL_addsDefaultVersionPathForHostOnlyInput() {
        let normalized = OpenAICompatibleClient.normalizedBaseURL(
            "127.0.0.1:11434",
            defaultBaseURL: "http://127.0.0.1:11434/v1"
        )

        XCTAssertEqual(normalized, "http://127.0.0.1:11434/v1")
    }

    func test_parseAvailableModelIdentifiers_supportsOpenAIAndNativeOllamaFormats() throws {
        let openAIData = try XCTUnwrap("""
        { "data": [{ "id": "qwen2.5:3b" }, { "id": "gemma3:4b" }] }
        """.data(using: .utf8))
        let nativeOllamaData = try XCTUnwrap("""
        { "models": [{ "name": "qwen2.5:3b" }, { "model": "gemma3:4b" }] }
        """.data(using: .utf8))

        XCTAssertEqual(
            OpenAICompatibleClient.parseAvailableModelIdentifiers(from: openAIData),
            ["qwen2.5:3b", "gemma3:4b"]
        )
        XCTAssertEqual(
            OpenAICompatibleClient.parseAvailableModelIdentifiers(from: nativeOllamaData),
            ["qwen2.5:3b", "gemma3:4b"]
        )
    }

    func test_complete_postsExpectedChatCompletionsRequest() async throws {
        let session = makeSession()
        let expectedResponse = try XCTUnwrap("""
        { "choices": [{ "message": { "content": "OK" } }] }
        """.data(using: .utf8))
        MockURLProtocol.configure(handlers: [
            { (request: URLRequest) in
                let response = HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, expectedResponse)
            }
        ])

        let client = OpenAICompatibleClient(
            baseURL: "http://127.0.0.1:11434/v1/",
            apiKey: "ollama",
            timeout: 12,
            session: session
        )

        let result = try await client.complete(
            model: "qwen2.5:3b",
            systemPrompt: "Reply with exactly: OK",
            userMessage: "test"
        )

        XCTAssertEqual(result, "OK")
        let request = try XCTUnwrap(MockURLProtocol.requests().first)
        XCTAssertEqual(request.url?.absoluteString, "http://127.0.0.1:11434/v1/chat/completions")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer ollama")

        let bodyData = try requestBody(from: request)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        XCTAssertEqual(json["model"] as? String, "qwen2.5:3b")
        XCTAssertEqual(json["temperature"] as? Double, 0.0)
        XCTAssertNotNil(json["messages"] as? [[String: Any]])
    }

    func test_ollamaNormalizedBaseURL_upgradesNativeAPIInputsToOpenAICompatibilityURL() {
        XCTAssertEqual(
            OllamaProvider.normalizedBaseURL("http://localhost:11434/api"),
            "http://localhost:11434/v1"
        )
        XCTAssertEqual(
            OllamaProvider.normalizedBaseURL("localhost:11434"),
            "http://localhost:11434/v1"
        )
    }

    func test_ollamaIsAvailable_fallsBackToNativeTagsEndpoint() async {
        let session = makeSession()
        let nativeTags = """
        { "models": [{ "name": "qwen2.5:3b" }] }
        """.data(using: .utf8)!
        MockURLProtocol.configure(handlers: [
            { (request: URLRequest) in
                let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            },
            { (request: URLRequest) in
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, nativeTags)
            }
        ])

        let provider = OllamaProvider(model: "qwen2.5:3b", baseURL: "localhost:11434", session: session)

        let isAvailable = await provider.isAvailable()

        XCTAssertTrue(isAvailable)
        let urls = MockURLProtocol.requests().compactMap { $0.url?.absoluteString }
        XCTAssertEqual(urls, [
            "http://localhost:11434/v1/models",
            "http://localhost:11434/api/tags"
        ])
    }

    func test_ollamaCorrectText_fallsBackToNativeChatWhenOpenAICompatibilityChatFails() async throws {
        let session = makeSession()
        let nativeTags = """
        { "models": [{ "name": "qwen2.5:3b" }] }
        """.data(using: .utf8)!
        let nativeChat = """
        { "message": { "content": "<think>ignore</think> Fixed text." } }
        """.data(using: .utf8)!
        MockURLProtocol.configure(handlers: [
            { (request: URLRequest) in
                let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            },
            { (request: URLRequest) in
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, nativeTags)
            },
            { (request: URLRequest) in
                let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            },
            { (request: URLRequest) in
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, nativeChat)
            }
        ])

        let provider = OllamaProvider(model: "qwen2.5:3b", baseURL: "http://127.0.0.1:11434/api", session: session)

        let result = try await provider.correctText(
            "helo world",
            language: .english,
            promptDictionary: "None",
            userRules: ""
        )

        XCTAssertEqual(result, "Fixed text.")
        let urls = MockURLProtocol.requests().compactMap { $0.url?.absoluteString }
        XCTAssertEqual(urls, [
            "http://127.0.0.1:11434/v1/models",
            "http://127.0.0.1:11434/api/tags",
            "http://127.0.0.1:11434/v1/chat/completions",
            "http://127.0.0.1:11434/api/chat"
        ])
    }
}
