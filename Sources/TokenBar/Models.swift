import Foundation

struct TokenCounts: Decodable, Equatable, Sendable {
    let input: Int
    let cachedInput: Int
    let output: Int
    let reasoningOutput: Int
    let total: Int

    init(input: Int, cachedInput: Int, output: Int, reasoningOutput: Int, total: Int) {
        self.input = max(0, input)
        self.cachedInput = max(0, cachedInput)
        self.output = max(0, output)
        self.reasoningOutput = max(0, reasoningOutput)
        self.total = max(0, total)
    }

    enum CodingKeys: String, CodingKey {
        case input = "input_tokens"
        case cachedInput = "cached_input_tokens"
        case output = "output_tokens"
        case reasoningOutput = "reasoning_output_tokens"
        case total = "total_tokens"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            input: try values.decodeIfPresent(Int.self, forKey: .input) ?? 0,
            cachedInput: try values.decodeIfPresent(Int.self, forKey: .cachedInput) ?? 0,
            output: try values.decodeIfPresent(Int.self, forKey: .output) ?? 0,
            reasoningOutput: try values.decodeIfPresent(Int.self, forKey: .reasoningOutput) ?? 0,
            total: try values.decodeIfPresent(Int.self, forKey: .total) ?? 0)
    }

    var uncachedInput: Int {
        max(0, self.input - self.cachedInput)
    }
}

struct LiveTokenSnapshot: Equatable, Sendable {
    let threadID: String
    let model: String?
    let recordedAt: Date
    let current: TokenCounts
}

struct QuotaWindow: Equatable, Identifiable, Sendable {
    enum Kind: String, Sendable {
        case session
        case weekly
        case other
    }

    let kind: Kind
    let usedPercent: Double
    let windowMinutes: Int?
    let resetsAt: Date?

    var id: String {
        "\(self.kind.rawValue)-\(self.windowMinutes ?? 0)"
    }

    var remainingPercent: Double {
        min(100, max(0, 100 - self.usedPercent))
    }

    var title: String {
        switch self.kind {
        case .session:
            "5 小时配额"
        case .weekly:
            "每周配额"
        case .other:
            "使用配额"
        }
    }
}

struct QuotaSnapshot: Equatable, Sendable {
    let windows: [QuotaWindow]
    let fetchedAt: Date

    var displayWindow: QuotaWindow? {
        self.windows.min(by: { $0.remainingPercent < $1.remainingPercent })
    }
}

enum QuotaState: Equatable, Sendable {
    case loading
    case available(QuotaSnapshot)
    case tokenOnly
    case failed(String)

    var snapshot: QuotaSnapshot? {
        guard case let .available(snapshot) = self else { return nil }
        return snapshot
    }

    var hidesQuota: Bool {
        if case .tokenOnly = self {
            return true
        }
        return false
    }
}

enum CompactNumber {
    static func string(_ value: Int) -> String {
        let value = max(0, value)
        if value < 1_000 {
            return "\(value)"
        }
        if value < 1_000_000 {
            return self.scaled(value, divisor: 1_000, suffix: "K")
        }
        if value < 1_000_000_000 {
            return self.scaled(value, divisor: 1_000_000, suffix: "M")
        }
        return self.scaled(value, divisor: 1_000_000_000, suffix: "B")
    }

    static func exact(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }

    private static func scaled(_ value: Int, divisor: Int, suffix: String) -> String {
        let number = Double(value) / Double(divisor)
        var text = String(format: number >= 100 ? "%.1f" : "%.1f", number)
        while text.contains("."), text.last == "0" {
            text.removeLast()
        }
        if text.last == "." {
            text.removeLast()
        }
        return text + suffix
    }
}

enum RelativeTimeText {
    static func string(since date: Date, now: Date = Date()) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        if seconds < 5 {
            return "正在更新"
        }
        if seconds < 60 {
            return "\(Int(seconds)) 秒前"
        }
        if seconds < 3_600 {
            return "\(Int(seconds / 60)) 分钟前"
        }
        return "\(Int(seconds / 3_600)) 小时前"
    }
}
