import Foundation

@MainActor
final class AppModel {
    private(set) var tokenSnapshot: LiveTokenSnapshot? {
        didSet {
            if oldValue != self.tokenSnapshot { self.onChange?() }
        }
    }

    private(set) var quotaState: QuotaState = .loading {
        didSet {
            if oldValue != self.quotaState { self.onChange?() }
        }
    }

    private(set) var tokenError: String? {
        didSet {
            if oldValue != self.tokenError { self.onChange?() }
        }
    }

    private(set) var isRefreshingQuota = false {
        didSet {
            if oldValue != self.isRefreshingQuota { self.onChange?() }
        }
    }

    private var lastSuccessfulTokenPollAt: Date?
    var onChange: (() -> Void)?

    private let tokenMonitor = TokenMonitor()
    private let quotaClient = QuotaClient()
    private var monitorTask: Task<Void, Never>?
    private var manualRefreshTask: Task<Void, Never>?
    private var nextQuotaRefresh = Date.distantPast

    func start() {
        guard self.monitorTask == nil else { return }
        self.monitorTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refreshToken()
                if Date() >= self.nextQuotaRefresh {
                    await self.refreshQuota()
                }
                let delay = self.pollDelay()
                do {
                    try await Task.sleep(for: .milliseconds(delay))
                } catch {
                    return
                }
            }
        }
    }

    func stop() {
        self.monitorTask?.cancel()
        self.monitorTask = nil
        self.manualRefreshTask?.cancel()
        self.manualRefreshTask = nil
    }

    func manualRefresh() {
        self.manualRefreshTask?.cancel()
        self.manualRefreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshToken()
            await self.refreshQuota()
        }
    }

    #if DEBUG
    func loadQAPreviewData(now: Date = Date()) {
        self.lastSuccessfulTokenPollAt = now
        self.tokenSnapshot = LiveTokenSnapshot(
            threadID: "qa-preview",
            model: "gpt-5.6-sol",
            recordedAt: now,
            current: TokenCounts(
                input: 39_840,
                cachedInput: 31_200,
                output: 2_840,
                reasoningOutput: 1_120,
                total: 42_680))
        self.quotaState = .available(QuotaSnapshot(
            windows: [
                QuotaWindow(
                    kind: .session,
                    usedPercent: 28,
                    windowMinutes: 300,
                    resetsAt: now.addingTimeInterval(2 * 60 * 60 + 18 * 60)),
                QuotaWindow(
                    kind: .weekly,
                    usedPercent: 16,
                    windowMinutes: 10_080,
                    resetsAt: now.addingTimeInterval(4 * 24 * 60 * 60 + 7 * 60 * 60)),
            ],
            fetchedAt: now))
        self.tokenError = nil
    }
    #endif

    var activityText: String {
        guard self.tokenSnapshot != nil else {
            return self.tokenError ?? "等待任务"
        }
        if self.tokenError != nil {
            return "等待更新"
        }
        return self.isActivelyUpdating ? "实时监听" : "正在同步"
    }

    var isActivelyUpdating: Bool {
        #if DEBUG
        if self.tokenSnapshot?.threadID == "qa-preview" {
            return true
        }
        #endif
        guard let lastSuccessfulTokenPollAt else { return false }
        return Date().timeIntervalSince(lastSuccessfulTokenPollAt) < 3
    }

    private func refreshToken() async {
        do {
            let wasActivelyUpdating = self.isActivelyUpdating
            let snapshot = try await self.tokenMonitor.poll()
            self.lastSuccessfulTokenPollAt = Date()
            if snapshot != self.tokenSnapshot {
                self.tokenSnapshot = snapshot
            } else if !wasActivelyUpdating {
                self.onChange?()
            }
            self.tokenError = nil
        } catch is CancellationError {
            return
        } catch {
            self.tokenError = error.localizedDescription
        }
    }

    private func refreshQuota() async {
        guard !self.isRefreshingQuota else { return }
        self.isRefreshingQuota = true
        defer { self.isRefreshingQuota = false }
        do {
            switch try await self.quotaClient.fetch() {
            case let .available(snapshot):
                self.quotaState = .available(snapshot)
            case .unavailable:
                self.quotaState = .tokenOnly
            }
            self.nextQuotaRefresh = Date().addingTimeInterval(5 * 60)
        } catch is CancellationError {
            return
        } catch {
            self.quotaState = .failed(error.localizedDescription)
            self.nextQuotaRefresh = Date().addingTimeInterval(60)
        }
    }

    private func pollDelay() -> Int64 {
        guard let recordedAt = self.tokenSnapshot?.recordedAt else { return 800 }
        let age = Date().timeIntervalSince(recordedAt)
        if age < 15 {
            return 400
        }
        if age < 60 {
            return 700
        }
        return 1_000
    }
}
