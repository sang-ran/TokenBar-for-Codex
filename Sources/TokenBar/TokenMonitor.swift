import Foundation
import SQLite3

actor TokenMonitor {
    enum MonitorError: LocalizedError {
        case codexDataMissing
        case noActiveTask
        case databaseUnavailable

        var errorDescription: String? {
            switch self {
            case .codexDataMissing:
                "未找到 Codex 本地数据"
            case .noActiveTask:
                "正在等待活跃的 Codex 任务"
            case .databaseUnavailable:
                "暂时无法读取 Codex 任务"
            }
        }
    }

    private struct ActiveThread: Equatable {
        let id: String
        let rolloutPath: String
        let model: String?
    }

    private struct Envelope: Decodable {
        let timestamp: String?
        let type: String
        let payload: Payload?
    }

    private struct Payload: Decodable {
        let type: String
        let info: Info?
    }

    private struct Info: Decodable {
        let lastUsage: TokenCounts?

        enum CodingKeys: String, CodingKey {
            case lastUsage = "last_token_usage"
        }
    }

    private let codexHome: URL
    private var activeThread: ActiveThread?
    private var nextDiscoveryAt = Date.distantPast
    private var readOffset: UInt64 = 0
    private var pending = Data()
    private var latest: LiveTokenSnapshot?

    init(codexHome: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")) {
        self.codexHome = codexHome
    }

    func poll(now: Date = Date()) throws -> LiveTokenSnapshot? {
        if self.activeThread == nil || now >= self.nextDiscoveryAt {
            try self.discoverActiveThread()
            self.nextDiscoveryAt = now.addingTimeInterval(1)
        }
        guard let activeThread else {
            throw MonitorError.noActiveTask
        }
        try self.readNewEvents(for: activeThread)
        return self.latest
    }

    private func discoverActiveThread() throws {
        guard FileManager.default.fileExists(atPath: self.codexHome.path) else {
            throw MonitorError.codexDataMissing
        }
        let databaseURL = try self.newestDatabase()
        let discovered = try self.queryActiveThread(databaseURL)
        guard discovered != self.activeThread else { return }

        self.activeThread = discovered
        self.readOffset = 0
        self.pending.removeAll(keepingCapacity: true)
        self.latest = nil
    }

    private func newestDatabase() throws -> URL {
        let files = try FileManager.default.contentsOfDirectory(
            at: self.codexHome,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles])
            .filter {
                $0.lastPathComponent.hasPrefix("state_") && $0.pathExtension == "sqlite"
            }
        guard let newest = files.max(by: {
            let left = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
                ?? .distantPast
            let right = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
                ?? .distantPast
            return left < right
        }) else {
            throw MonitorError.databaseUnavailable
        }
        return newest
    }

    private func queryActiveThread(_ databaseURL: URL) throws -> ActiveThread {
        var database: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            sqlite3_close(database)
            throw MonitorError.databaseUnavailable
        }
        defer { sqlite3_close(database) }
        sqlite3_busy_timeout(database, 200)

        let sql = """
        SELECT id, rollout_path, model
        FROM threads
        WHERE archived = 0 AND rollout_path IS NOT NULL AND rollout_path != ''
        ORDER BY updated_at_ms DESC, recency_at_ms DESC
        LIMIT 1
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw MonitorError.databaseUnavailable
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW,
              let id = sqlite3_column_text(statement, 0),
              let path = sqlite3_column_text(statement, 1)
        else {
            throw MonitorError.noActiveTask
        }
        return ActiveThread(
            id: String(cString: id),
            rolloutPath: String(cString: path),
            model: sqlite3_column_text(statement, 2).map { String(cString: $0) })
    }

    private func readNewEvents(for thread: ActiveThread) throws {
        let fileURL = URL(fileURLWithPath: thread.rolloutPath)
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let size = (attributes[.size] as? NSNumber)?.uint64Value ?? 0

        if size < self.readOffset {
            self.readOffset = 0
            self.pending.removeAll(keepingCapacity: true)
        }

        let initialTailLimit: UInt64 = 4 * 1_024 * 1_024
        var discardLeadingPartialLine = false
        if self.readOffset == 0, size > initialTailLimit {
            self.readOffset = size - initialTailLimit
            discardLeadingPartialLine = true
        }
        guard size > self.readOffset else { return }

        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        try handle.seek(toOffset: self.readOffset)
        let data = try handle.read(upToCount: Int(size - self.readOffset)) ?? Data()
        self.readOffset = size
        guard !data.isEmpty else { return }
        self.pending.append(data)

        if discardLeadingPartialLine, let newline = self.pending.firstIndex(of: 0x0A) {
            self.pending.removeSubrange(...newline)
        }

        while let newline = self.pending.firstIndex(of: 0x0A) {
            let line = self.pending.subdata(in: self.pending.startIndex..<newline)
            self.pending.removeSubrange(...newline)
            guard line.range(of: Data(#""token_count""#.utf8)) != nil,
                  let event = try? JSONDecoder().decode(Envelope.self, from: line),
                  event.type == "event_msg",
                  event.payload?.type == "token_count",
                  let current = event.payload?.info?.lastUsage
            else { continue }

            self.latest = LiveTokenSnapshot(
                threadID: thread.id,
                model: thread.model,
                recordedAt: event.timestamp.flatMap(Self.parseTimestamp) ?? Date(),
                current: current)
        }
    }

    private static func parseTimestamp(_ text: String) -> Date? {
        let precise = ISO8601DateFormatter()
        precise.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return precise.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }
}
