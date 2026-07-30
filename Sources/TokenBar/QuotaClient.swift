import Foundation

actor QuotaClient {
    enum FetchResult: Sendable {
        case available(QuotaSnapshot)
        case unavailable
    }

    enum QuotaError: LocalizedError {
        case codexNotFound
        case launchFailed(String)
        case connectionClosed
        case invalidResponse
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .codexNotFound:
                "未找到 Codex CLI"
            case let .launchFailed(message):
                "无法启动 Codex：\(message)"
            case .connectionClosed:
                "Codex 配额连接已关闭"
            case .invalidResponse:
                "Codex 返回了无法识别的配额数据"
            case let .serverError(message):
                "Codex 配额错误：\(message)"
            }
        }
    }

    private struct RateLimitsResult: Decodable {
        let rateLimits: RateLimits
    }

    private struct RateLimits: Decodable {
        let primary: RateWindow?
        let secondary: RateWindow?
    }

    private struct RateWindow: Decodable {
        let usedPercent: Double
        let windowDurationMins: Int?
        let resetsAt: Int?
    }

    private final class ProcessBox: @unchecked Sendable {
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        var buffer = Data()
    }

    func fetch() async throws -> FetchResult {
        try await Task.detached(priority: .utility) {
            try Self.fetchSynchronously()
        }.value
    }

    private nonisolated static func fetchSynchronously() throws -> FetchResult {
        guard let executable = self.codexExecutable() else {
            throw QuotaError.codexNotFound
        }

        let box = ProcessBox()
        box.process.executableURL = executable
        box.process.arguments = ["-s", "read-only", "-a", "untrusted", "app-server"]
        box.process.standardInput = box.input
        box.process.standardOutput = box.output
        box.process.standardError = FileHandle.nullDevice

        do {
            try box.process.run()
        } catch {
            throw QuotaError.launchFailed(error.localizedDescription)
        }

        let timeout = DispatchWorkItem {
            if box.process.isRunning {
                box.process.terminate()
            }
        }
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 10, execute: timeout)
        defer {
            timeout.cancel()
            if box.process.isRunning {
                box.process.terminate()
            }
            try? box.input.fileHandleForWriting.close()
            try? box.output.fileHandleForReading.close()
        }

        try self.send(
            [
                "id": 1,
                "method": "initialize",
                "params": [
                    "clientInfo": [
                        "name": "tokenbar-for-codex",
                        "version": "0.1.0",
                    ],
                ],
            ],
            to: box.input.fileHandleForWriting)
        _ = try self.readMessage(id: 1, from: box)

        try self.send(
            ["method": "initialized", "params": [:] as [String: Any]],
            to: box.input.fileHandleForWriting)
        try self.send(
            ["id": 2, "method": "account/read", "params": [:] as [String: Any]],
            to: box.input.fileHandleForWriting)

        let accountMessage = try self.readMessage(id: 2, from: box)
        if let result = accountMessage["result"] as? [String: Any],
           let account = result["account"] as? [String: Any],
           let type = account["type"] as? String,
           type.lowercased().replacingOccurrences(of: "_", with: "") == "apikey"
        {
            return .unavailable
        }

        try self.send(
            ["id": 3, "method": "account/rateLimits/read", "params": [:] as [String: Any]],
            to: box.input.fileHandleForWriting)
        let message = try self.readMessage(id: 3, from: box)
        if let error = message["error"] as? [String: Any] {
            throw QuotaError.serverError(error["message"] as? String ?? "unknown")
        }
        guard let result = message["result"] else {
            throw QuotaError.invalidResponse
        }

        let data = try JSONSerialization.data(withJSONObject: result)
        let response = try JSONDecoder().decode(RateLimitsResult.self, from: data)
        var windows: [QuotaWindow] = []
        if let primary = response.rateLimits.primary {
            windows.append(self.window(primary))
        }
        if let secondary = response.rateLimits.secondary {
            windows.append(self.window(secondary))
        }
        guard !windows.isEmpty else { return .unavailable }
        return .available(QuotaSnapshot(windows: windows, fetchedAt: Date()))
    }

    private nonisolated static func codexExecutable() -> URL? {
        let environment = ProcessInfo.processInfo.environment
        let candidates = [
            environment["TOKENBAR_CODEX_PATH"],
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
        ].compactMap { $0 }
        return candidates
            .map(URL.init(fileURLWithPath:))
            .first(where: { FileManager.default.isExecutableFile(atPath: $0.path) })
    }

    private nonisolated static func send(_ object: [String: Any], to handle: FileHandle) throws {
        var data = try JSONSerialization.data(withJSONObject: object)
        data.append(0x0A)
        try handle.write(contentsOf: data)
    }

    private nonisolated static func readMessage(id: Int, from box: ProcessBox) throws -> [String: Any] {
        while true {
            while let newline = box.buffer.firstIndex(of: 0x0A) {
                let line = box.buffer.subdata(in: box.buffer.startIndex..<newline)
                box.buffer.removeSubrange(...newline)
                guard !line.isEmpty,
                      let message = try? JSONSerialization.jsonObject(with: line) as? [String: Any]
                else { continue }
                let messageID = (message["id"] as? NSNumber)?.intValue ?? message["id"] as? Int
                if messageID == id {
                    return message
                }
            }

            let chunk = box.output.fileHandleForReading.availableData
            guard !chunk.isEmpty else {
                throw QuotaError.connectionClosed
            }
            box.buffer.append(chunk)
        }
    }

    private nonisolated static func window(_ value: RateWindow) -> QuotaWindow {
        let kind: QuotaWindow.Kind
        switch value.windowDurationMins {
        case 300:
            kind = .session
        case 10_080:
            kind = .weekly
        default:
            kind = .other
        }
        return QuotaWindow(
            kind: kind,
            usedPercent: value.usedPercent,
            windowMinutes: value.windowDurationMins,
            resetsAt: value.resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) })
    }
}
