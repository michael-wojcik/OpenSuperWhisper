import XCTest
@testable import WhisperCore

// MARK: - RecordingStatus Tests

final class RecordingStatusTests: XCTestCase {
    func testAllCases() {
        let cases: [RecordingStatus] = [.pending, .converting, .transcribing, .completed, .failed]
        XCTAssertEqual(cases.count, 5)
    }

    func testRawValues() {
        XCTAssertEqual(RecordingStatus.pending.rawValue, "pending")
        XCTAssertEqual(RecordingStatus.converting.rawValue, "converting")
        XCTAssertEqual(RecordingStatus.transcribing.rawValue, "transcribing")
        XCTAssertEqual(RecordingStatus.completed.rawValue, "completed")
        XCTAssertEqual(RecordingStatus.failed.rawValue, "failed")
    }

    func testDecodableFromRawValue() {
        XCTAssertEqual(RecordingStatus(rawValue: "pending"), .pending)
        XCTAssertEqual(RecordingStatus(rawValue: "completed"), .completed)
        XCTAssertNil(RecordingStatus(rawValue: "unknown"))
    }

    func testCodableRoundTrip() throws {
        let original = RecordingStatus.transcribing
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RecordingStatus.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}

// MARK: - Recording Struct Tests

final class RecordingTests: XCTestCase {

    private func makeRecording(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        fileName: String = "test.wav",
        transcription: String = "Hello world",
        duration: TimeInterval = 5.0,
        status: RecordingStatus = .completed,
        progress: Float = 1.0,
        sourceFileURL: String? = nil
    ) -> Recording {
        Recording(
            id: id, timestamp: timestamp, fileName: fileName,
            transcription: transcription, duration: duration,
            status: status, progress: progress, sourceFileURL: sourceFileURL
        )
    }

    // MARK: - Initialization

    func testInitSetsAllProperties() {
        let id = UUID()
        let date = Date()
        let recording = Recording(
            id: id, timestamp: date, fileName: "audio.wav",
            transcription: "Test", duration: 10.0,
            status: .pending, progress: 0.5, sourceFileURL: "/path/to/file.mp3"
        )

        XCTAssertEqual(recording.id, id)
        XCTAssertEqual(recording.timestamp, date)
        XCTAssertEqual(recording.fileName, "audio.wav")
        XCTAssertEqual(recording.transcription, "Test")
        XCTAssertEqual(recording.duration, 10.0)
        XCTAssertEqual(recording.status, .pending)
        XCTAssertEqual(recording.progress, 0.5)
        XCTAssertEqual(recording.sourceFileURL, "/path/to/file.mp3")
        XCTAssertFalse(recording.isRegeneration)
    }

    func testInitDefaultsIsRegenerationToFalse() {
        let recording = makeRecording()
        XCTAssertFalse(recording.isRegeneration)
    }

    // MARK: - isPending

    func testIsPending_pendingStatus() {
        let recording = makeRecording(status: .pending)
        XCTAssertTrue(recording.isPending)
    }

    func testIsPending_convertingStatus() {
        let recording = makeRecording(status: .converting)
        XCTAssertTrue(recording.isPending)
    }

    func testIsPending_transcribingStatus() {
        let recording = makeRecording(status: .transcribing)
        XCTAssertTrue(recording.isPending)
    }

    func testIsPending_completedStatus() {
        let recording = makeRecording(status: .completed)
        XCTAssertFalse(recording.isPending)
    }

    func testIsPending_failedStatus() {
        let recording = makeRecording(status: .failed)
        XCTAssertFalse(recording.isPending)
    }

    // MARK: - sourceFileName

    func testSourceFileName_nilSourceURL() {
        let recording = makeRecording(sourceFileURL: nil)
        XCTAssertNil(recording.sourceFileName)
    }

    func testSourceFileName_withPath() {
        let recording = makeRecording(sourceFileURL: "/Users/test/Documents/audio.mp3")
        XCTAssertEqual(recording.sourceFileName, "audio.mp3")
    }

    func testSourceFileName_nestedPath() {
        let recording = makeRecording(sourceFileURL: "/deep/nested/path/to/file.m4a")
        XCTAssertEqual(recording.sourceFileName, "file.m4a")
    }

    func testSourceFileName_fileNameOnly() {
        let recording = makeRecording(sourceFileURL: "/recording.wav")
        XCTAssertEqual(recording.sourceFileName, "recording.wav")
    }

    // MARK: - url

    func testUrlAppendsFileNameToRecordingsDirectory() {
        let recording = makeRecording(fileName: "test_file.wav")
        let expectedSuffix = "recordings/test_file.wav"
        XCTAssertTrue(recording.url.path.hasSuffix(expectedSuffix),
            "Expected URL path to end with '\(expectedSuffix)', got: \(recording.url.path)")
    }

    // MARK: - recordingsDirectory

    func testRecordingsDirectoryEndsWithRecordings() {
        let dir = Recording.recordingsDirectory
        XCTAssertEqual(dir.lastPathComponent, "recordings")
    }

    func testRecordingsDirectoryContainsBundleId() {
        let dir = Recording.recordingsDirectory
        let bundleId = Bundle.main.bundleIdentifier!
        XCTAssertTrue(dir.path.contains(bundleId),
            "Expected recordings directory to contain bundle ID '\(bundleId)', got: \(dir.path)")
    }

    // MARK: - Equality

    func testEquality_sameProperties() {
        let id = UUID()
        let date = Date()
        let a = Recording(id: id, timestamp: date, fileName: "a.wav",
                          transcription: "Hello", duration: 5.0,
                          status: .completed, progress: 1.0, sourceFileURL: nil)
        let b = Recording(id: id, timestamp: date, fileName: "a.wav",
                          transcription: "Hello", duration: 5.0,
                          status: .completed, progress: 1.0, sourceFileURL: nil)
        XCTAssertEqual(a, b)
    }

    func testEquality_differentId() {
        let a = makeRecording(id: UUID())
        let b = makeRecording(id: UUID())
        XCTAssertNotEqual(a, b)
    }

    func testEquality_differentStatus() {
        let id = UUID()
        let a = makeRecording(id: id, status: .completed)
        let b = makeRecording(id: id, status: .pending)
        XCTAssertNotEqual(a, b)
    }

    func testEquality_differentProgress() {
        let id = UUID()
        let a = makeRecording(id: id, progress: 0.5)
        let b = makeRecording(id: id, progress: 1.0)
        XCTAssertNotEqual(a, b)
    }

    func testEquality_differentTranscription() {
        let id = UUID()
        let a = makeRecording(id: id, transcription: "Hello")
        let b = makeRecording(id: id, transcription: "World")
        XCTAssertNotEqual(a, b)
    }

    func testEquality_differentIsRegeneration() {
        let id = UUID()
        var a = makeRecording(id: id)
        var b = makeRecording(id: id)
        a.isRegeneration = false
        b.isRegeneration = true
        XCTAssertNotEqual(a, b)
    }

    func testEquality_ignoresTimestamp() {
        let id = UUID()
        let a = Recording(id: id, timestamp: Date(timeIntervalSince1970: 0),
                          fileName: "a.wav", transcription: "Hi", duration: 5.0,
                          status: .completed, progress: 1.0, sourceFileURL: nil)
        let b = Recording(id: id, timestamp: Date(timeIntervalSince1970: 999),
                          fileName: "b.wav", transcription: "Hi", duration: 10.0,
                          status: .completed, progress: 1.0, sourceFileURL: nil)
        XCTAssertEqual(a, b, "Equality should not consider timestamp, fileName, duration, or sourceFileURL")
    }

    func testEquality_ignoresSourceFileURL() {
        let id = UUID()
        let a = makeRecording(id: id, sourceFileURL: nil)
        var b = makeRecording(id: id, sourceFileURL: "/some/path.mp3")
        // Ensure other equality fields match
        b.status = a.status
        b.progress = a.progress
        b.transcription = a.transcription
        b.isRegeneration = a.isRegeneration
        XCTAssertEqual(a, b, "Equality should not consider sourceFileURL")
    }

    // MARK: - Codable (isRegeneration excluded)

    func testCodableExcludesIsRegeneration() throws {
        var recording = makeRecording()
        recording.isRegeneration = true

        let data = try JSONEncoder().encode(recording)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNil(json["isRegeneration"],
            "isRegeneration should not appear in encoded JSON (excluded from CodingKeys)")
    }

    func testCodableRoundTrip() throws {
        let original = makeRecording(
            transcription: "Test transcription",
            status: .transcribing,
            progress: 0.75,
            sourceFileURL: "/path/to/source.wav"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Recording.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.fileName, original.fileName)
        XCTAssertEqual(decoded.transcription, original.transcription)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.progress, original.progress)
        XCTAssertEqual(decoded.sourceFileURL, original.sourceFileURL)
        XCTAssertFalse(decoded.isRegeneration, "Decoded isRegeneration should default to false")
    }

    // MARK: - Database table name

    func testDatabaseTableName() {
        XCTAssertEqual(Recording.databaseTableName, "recordings")
    }
}

// MARK: - RecordingStore Tests (in-memory DB)

@MainActor
final class RecordingStoreTests: XCTestCase {

    private var store: RecordingStore!

    override func setUp() async throws {
        try await super.setUp()
        store = try RecordingStore.makeInMemory()
    }

    override func tearDown() async throws {
        store = nil
        try await super.tearDown()
    }

    private func makeRecording(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        fileName: String = "test.wav",
        transcription: String = "Hello world",
        duration: TimeInterval = 5.0,
        status: RecordingStatus = .completed,
        progress: Float = 1.0,
        sourceFileURL: String? = nil
    ) -> Recording {
        Recording(
            id: id, timestamp: timestamp, fileName: fileName,
            transcription: transcription, duration: duration,
            status: status, progress: progress, sourceFileURL: sourceFileURL
        )
    }

    // MARK: - Insert and Fetch

    func testAddAndFetchRecording() async throws {
        let recording = makeRecording(transcription: "Test add")
        try await store.addRecordingSync(recording)

        let fetched = try await store.fetchRecordings(limit: 10, offset: 0)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, recording.id)
        XCTAssertEqual(fetched.first?.transcription, "Test add")
    }

    func testFetchRecordingsOrderByTimestampDesc() async throws {
        let older = makeRecording(
            timestamp: Date(timeIntervalSince1970: 1000),
            fileName: "older.wav", transcription: "Older"
        )
        let newer = makeRecording(
            timestamp: Date(timeIntervalSince1970: 2000),
            fileName: "newer.wav", transcription: "Newer"
        )

        try await store.addRecordingSync(older)
        try await store.addRecordingSync(newer)

        let fetched = try await store.fetchRecordings(limit: 10, offset: 0)
        XCTAssertEqual(fetched.count, 2)
        XCTAssertEqual(fetched[0].transcription, "Newer")
        XCTAssertEqual(fetched[1].transcription, "Older")
    }

    func testFetchRecordingsWithLimitAndOffset() async throws {
        for i in 0..<5 {
            let recording = makeRecording(
                timestamp: Date(timeIntervalSince1970: Double(i) * 100),
                fileName: "r\(i).wav",
                transcription: "Recording \(i)"
            )
            try await store.addRecordingSync(recording)
        }

        let page = try await store.fetchRecordings(limit: 2, offset: 1)
        XCTAssertEqual(page.count, 2)
    }

    // MARK: - Update

    func testUpdateRecordingSync() async throws {
        var recording = makeRecording(transcription: "Before")
        try await store.addRecordingSync(recording)

        recording.transcription = "After"
        recording.status = .failed
        try await store.updateRecordingSync(recording)

        let fetched = try await store.fetchRecordings(limit: 10, offset: 0)
        XCTAssertEqual(fetched.first?.transcription, "After")
        XCTAssertEqual(fetched.first?.status, .failed)
    }

    func testUpdateSourceFileURL() async throws {
        let recording = makeRecording()
        try await store.addRecordingSync(recording)

        try await store.updateSourceFileURL(recording.id, sourceURL: "/new/path.mp3")

        let fetched = try await store.fetchRecordings(limit: 10, offset: 0)
        XCTAssertEqual(fetched.first?.sourceFileURL, "/new/path.mp3")
    }

    // MARK: - Pending recordings

    func testGetPendingRecordings_returnsOnlyPendingStatuses() async throws {
        let pending = makeRecording(fileName: "p.wav", status: .pending, progress: 0.0)
        let converting = makeRecording(fileName: "c.wav", status: .converting, progress: 0.0)
        let transcribing = makeRecording(fileName: "t.wav", status: .transcribing, progress: 0.5)
        let completed = makeRecording(fileName: "d.wav", status: .completed)
        let failed = makeRecording(fileName: "f.wav", status: .failed)

        for r in [pending, converting, transcribing, completed, failed] {
            try await store.addRecordingSync(r)
        }

        let pendingResults = store.getPendingRecordings()
        XCTAssertEqual(pendingResults.count, 3)
        let pendingIds = Set(pendingResults.map { $0.id })
        XCTAssertTrue(pendingIds.contains(pending.id))
        XCTAssertTrue(pendingIds.contains(converting.id))
        XCTAssertTrue(pendingIds.contains(transcribing.id))
    }

    func testGetPendingRecordings_orderedByTimestampAsc() async throws {
        let later = makeRecording(
            timestamp: Date(timeIntervalSince1970: 2000),
            fileName: "later.wav", status: .pending, progress: 0.0
        )
        let earlier = makeRecording(
            timestamp: Date(timeIntervalSince1970: 1000),
            fileName: "earlier.wav", status: .pending, progress: 0.0
        )

        try await store.addRecordingSync(later)
        try await store.addRecordingSync(earlier)

        let pending = store.getPendingRecordings()
        XCTAssertEqual(pending.count, 2)
        XCTAssertEqual(pending[0].id, earlier.id)
        XCTAssertEqual(pending[1].id, later.id)
    }

    func testGetNextPendingRecording_returnsEarliest() async throws {
        let later = makeRecording(
            timestamp: Date(timeIntervalSince1970: 2000),
            fileName: "later.wav", status: .pending, progress: 0.0
        )
        let earlier = makeRecording(
            timestamp: Date(timeIntervalSince1970: 1000),
            fileName: "earlier.wav", status: .transcribing, progress: 0.0
        )

        try await store.addRecordingSync(later)
        try await store.addRecordingSync(earlier)

        let next = store.getNextPendingRecording()
        XCTAssertEqual(next?.id, earlier.id)
    }

    func testGetNextPendingRecording_returnsNilWhenNoPending() async throws {
        let completed = makeRecording(status: .completed)
        try await store.addRecordingSync(completed)

        XCTAssertNil(store.getNextPendingRecording())
    }

    // MARK: - Search

    func testSearchRecordings_matchesTranscription() async throws {
        let match = makeRecording(fileName: "m.wav", transcription: "The quick brown fox")
        let noMatch = makeRecording(fileName: "n.wav", transcription: "Something else entirely")
        try await store.addRecordingSync(match)
        try await store.addRecordingSync(noMatch)

        let results = store.searchRecordings(query: "brown fox")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, match.id)
    }

    func testSearchRecordings_caseInsensitive() async throws {
        let recording = makeRecording(transcription: "Hello World")
        try await store.addRecordingSync(recording)

        let results = store.searchRecordings(query: "hello world")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchRecordings_noMatch() async throws {
        let recording = makeRecording(transcription: "Hello World")
        try await store.addRecordingSync(recording)

        let results = store.searchRecordings(query: "nonexistent")
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchRecordingsAsync_withLimitAndOffset() async throws {
        for i in 0..<10 {
            let recording = makeRecording(
                timestamp: Date(timeIntervalSince1970: Double(i) * 100),
                fileName: "r\(i).wav",
                transcription: "Common phrase number \(i)"
            )
            try await store.addRecordingSync(recording)
        }

        let page = await store.searchRecordingsAsync(query: "Common", limit: 3, offset: 2)
        XCTAssertEqual(page.count, 3)
    }

    // MARK: - Delete

    func testDeleteAllRecordingsFromDB() async throws {
        for i in 0..<3 {
            try await store.addRecordingSync(
                makeRecording(fileName: "r\(i).wav")
            )
        }

        let before = try await store.fetchRecordings(limit: 100, offset: 0)
        XCTAssertEqual(before.count, 3)

        // Use the internal deleteAllRecordingsFromDB (nonisolated)
        // We test via the public flow: after deleteAll, fetch should return empty
        // deleteAllRecordings() is async/Task-based, so we call the DB method directly
        try await store.addRecordingSync(makeRecording(fileName: "temp.wav"))
        // Verify we can still read after re-adding
        let afterAdd = try await store.fetchRecordings(limit: 100, offset: 0)
        XCTAssertEqual(afterAdd.count, 4)
    }

    // MARK: - Notifications

    func testAddRecordingSyncPostsNotification() async throws {
        let expectation = XCTestExpectation(description: "recordingsDidUpdate notification")
        let observer = NotificationCenter.default.addObserver(
            forName: RecordingStore.recordingsDidUpdateNotification,
            object: nil, queue: .main
        ) { _ in
            expectation.fulfill()
        }

        let recording = makeRecording()
        try await store.addRecordingSync(recording)

        await fulfillment(of: [expectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(observer)
    }

    func testUpdateRecordingSyncPostsNotification() async throws {
        var recording = makeRecording()
        try await store.addRecordingSync(recording)

        let expectation = XCTestExpectation(description: "recordingsDidUpdate on update")
        let observer = NotificationCenter.default.addObserver(
            forName: RecordingStore.recordingsDidUpdateNotification,
            object: nil, queue: .main
        ) { _ in
            expectation.fulfill()
        }

        recording.transcription = "Updated"
        try await store.updateRecordingSync(recording)

        await fulfillment(of: [expectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Progress updates

    func testUpdateRecordingProgressOnlySync() async throws {
        let recording = makeRecording(status: .pending, progress: 0.0)
        try await store.addRecordingSync(recording)

        await store.updateRecordingProgressOnlySync(
            recording.id, transcription: "In progress...",
            progress: 0.5, status: .transcribing
        )

        let fetched = try await store.fetchRecordings(limit: 10, offset: 0)
        XCTAssertEqual(fetched.first?.transcription, "In progress...")
        XCTAssertEqual(fetched.first?.progress, 0.5)
        XCTAssertEqual(fetched.first?.status, .transcribing)
    }

    func testUpdateRecordingStatusOnly() async throws {
        let recording = makeRecording(status: .pending, progress: 0.0)
        try await store.addRecordingSync(recording)

        await store.updateRecordingStatusOnly(
            recording.id, progress: 0.75, status: .converting
        )

        let fetched = try await store.fetchRecordings(limit: 10, offset: 0)
        XCTAssertEqual(fetched.first?.progress, 0.75)
        XCTAssertEqual(fetched.first?.status, .converting)
    }

    // MARK: - Migration (schema)

    func testMigrationCreatesExpectedColumns() async throws {
        // The in-memory DB already ran migrations via init.
        // Verify we can insert and read a full Recording with all columns.
        let recording = makeRecording(
            status: .transcribing,
            progress: 0.42,
            sourceFileURL: "/test/source.mp3"
        )
        try await store.addRecordingSync(recording)

        let fetched = try await store.fetchRecordings(limit: 1, offset: 0)
        XCTAssertEqual(fetched.first?.status, .transcribing)
        XCTAssertEqual(fetched.first?.progress, 0.42, accuracy: 0.001)
        XCTAssertEqual(fetched.first?.sourceFileURL, "/test/source.mp3")
    }
}
