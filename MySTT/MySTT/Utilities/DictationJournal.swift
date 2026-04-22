import Foundation

actor DictationJournal {
    private let recordsDirectoryURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(recordsDirectoryURL: URL = DictationJournal.defaultRecordsDirectoryURL()) {
        self.recordsDirectoryURL = recordsDirectoryURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        try? FileManager.default.createDirectory(
            at: recordsDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    func createRecord(
        rawText: String,
        finalText: String,
        language: Language,
        targetApp: TargetAppSnapshot?
    ) throws -> DictationRecord {
        let record = DictationRecord(
            rawText: rawText,
            finalText: finalText,
            language: language,
            targetApp: targetApp
        )
        try write(record)
        return record
    }

    func updateRecord(_ record: DictationRecord) throws {
        try write(record)
    }

    func markDelivery(recordID: UUID, result: PasteDeliveryResult) throws -> DictationRecord? {
        guard var record = try loadRecord(id: recordID) else { return nil }
        record.apply(result)
        try write(record)
        return record
    }

    func mostRecentRecoverableRecord() throws -> DictationRecord? {
        let records = try loadAllRecords()
        return records
            .filter { $0.requiresRecovery && $0.recoveryAttempts == 0 }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
    }

    func loadRecord(id: UUID) throws -> DictationRecord? {
        let url = recordURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try decoder.decode(DictationRecord.self, from: data)
    }

    func loadAllRecords() throws -> [DictationRecord] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: recordsDirectoryURL,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return try urls
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                let data = try Data(contentsOf: url)
                return try decoder.decode(DictationRecord.self, from: data)
            }
    }

    func markRecovered(recordID: UUID, note: String) throws -> DictationRecord? {
        guard var record = try loadRecord(id: recordID) else { return nil }
        record.markRecovered(note: note)
        try write(record)
        return record
    }

    private func write(_ record: DictationRecord) throws {
        let data = try encoder.encode(record)
        try data.write(to: recordURL(for: record.id), options: .atomic)
    }

    private func recordURL(for id: UUID) -> URL {
        recordsDirectoryURL.appendingPathComponent("\(id.uuidString).json")
    }

    static func defaultRecordsDirectoryURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".mystt", isDirectory: true)
            .appendingPathComponent("dictations", isDirectory: true)
    }
}
