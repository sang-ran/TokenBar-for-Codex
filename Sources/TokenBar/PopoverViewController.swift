import AppKit

@MainActor
final class TokenPopoverViewController: NSViewController {
    private let model: AppModel
    private let openSettings: () -> Void
    private let quit: () -> Void

    private let statusLabel = NSTextField(labelWithString: "")
    private let tokenLabel = NSTextField(labelWithString: "—")
    private let modelLabel = NSTextField(labelWithString: "")
    private let inputTile = MetricTileView(title: "Input")
    private let cachedTile = MetricTileView(title: "Cached")
    private let outputTile = MetricTileView(title: "Output")
    private let quotaStack = NSStackView()
    private let refreshButton = NSButton()
    private var activityTimer: Timer?

    init(model: AppModel, openSettings: @escaping () -> Void, quit: @escaping () -> Void) {
        self.model = model
        self.openSettings = openSettings
        self.quit = quit
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let root = NSView()
        root.translatesAutoresizingMaskIntoConstraints = false
        self.view = root

        let content = NSStackView()
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 13
        content.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(content)

        NSLayoutConstraint.activate([
            root.widthAnchor.constraint(equalToConstant: 320),
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            content.topAnchor.constraint(equalTo: root.topAnchor, constant: 15),
            content.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -13),
        ])

        content.addArrangedSubview(self.makeHeader())
        content.addArrangedSubview(Self.separator())
        content.addArrangedSubview(self.makeTokenSummary())
        content.addArrangedSubview(self.makeMetrics())

        self.quotaStack.orientation = .vertical
        self.quotaStack.alignment = .leading
        self.quotaStack.spacing = 11
        self.quotaStack.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(self.quotaStack)
        self.quotaStack.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true

        content.addArrangedSubview(Self.separator())
        content.addArrangedSubview(self.makeFooter())
        self.update()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.updateActivity()
        self.activityTimer = Timer.scheduledTimer(
            withTimeInterval: 3,
            repeats: true,
            block: { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.updateActivity()
                }
            })
    }

    override func viewDidDisappear() {
        self.activityTimer?.invalidate()
        self.activityTimer = nil
        super.viewDidDisappear()
    }

    func update() {
        guard self.isViewLoaded else { return }
        let usage = self.model.tokenSnapshot?.current
        self.tokenLabel.stringValue = usage.map { CompactNumber.exact($0.total) } ?? "—"
        self.modelLabel.stringValue = self.model.tokenSnapshot?.model ?? ""
        self.modelLabel.isHidden = self.modelLabel.stringValue.isEmpty
        self.inputTile.value = usage.map { CompactNumber.string($0.input) } ?? "—"
        self.cachedTile.value = usage.map { CompactNumber.string($0.cachedInput) } ?? "—"
        self.outputTile.value = usage.map { CompactNumber.string($0.output) } ?? "—"
        self.refreshButton.isEnabled = !self.model.isRefreshingQuota
        self.updateActivity()
        self.rebuildQuotaRows()
    }

    private func makeHeader() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let title = NSTextField(labelWithString: "TokenBar")
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false

        self.statusLabel.font = .systemFont(ofSize: 11)
        self.statusLabel.alignment = .right
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(title)
        container.addSubview(self.statusLabel)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            title.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            self.statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            self.statusLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            self.statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: title.trailingAnchor, constant: 12),
            container.widthAnchor.constraint(equalToConstant: 288),
        ])
        return container
    }

    private func makeTokenSummary() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 75).isActive = true
        container.widthAnchor.constraint(equalToConstant: 288).isActive = true

        let caption = NSTextField(labelWithString: "当前任务")
        caption.font = .systemFont(ofSize: 11)
        caption.textColor = .secondaryLabelColor
        caption.translatesAutoresizingMaskIntoConstraints = false

        self.tokenLabel.font = .systemFont(ofSize: 28, weight: .bold)
        self.tokenLabel.translatesAutoresizingMaskIntoConstraints = false
        self.tokenLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let unit = NSTextField(labelWithString: "tokens")
        unit.font = .systemFont(ofSize: 10)
        unit.textColor = .secondaryLabelColor
        unit.translatesAutoresizingMaskIntoConstraints = false

        self.modelLabel.font = .systemFont(ofSize: 10)
        self.modelLabel.textColor = .secondaryLabelColor
        self.modelLabel.alignment = .center
        self.modelLabel.wantsLayer = true
        self.modelLabel.layer?.cornerRadius = 9
        self.modelLabel.layer?.backgroundColor = NSColor.quaternaryLabelColor.cgColor
        self.modelLabel.translatesAutoresizingMaskIntoConstraints = false

        [caption, self.tokenLabel, unit, self.modelLabel].forEach(container.addSubview)
        NSLayoutConstraint.activate([
            caption.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            caption.topAnchor.constraint(equalTo: container.topAnchor),
            self.tokenLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            self.tokenLabel.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 1),
            unit.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            unit.topAnchor.constraint(equalTo: self.tokenLabel.bottomAnchor, constant: -2),
            self.modelLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            self.modelLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 3),
            self.modelLabel.heightAnchor.constraint(equalToConstant: 19),
            self.modelLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 126),
        ])
        return container
    }

    private func makeMetrics() -> NSView {
        let stack = NSStackView(views: [self.inputTile, self.cachedTile, self.outputTile])
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.widthAnchor.constraint(equalToConstant: 288),
            stack.heightAnchor.constraint(equalToConstant: 55),
        ])
        return stack
    }

    private func makeFooter() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 22).isActive = true
        container.widthAnchor.constraint(equalToConstant: 288).isActive = true

        self.refreshButton.title = "刷新"
        self.refreshButton.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        self.refreshButton.imagePosition = .imageLeading
        self.refreshButton.font = .systemFont(ofSize: 11)
        self.refreshButton.bezelStyle = .inline
        self.refreshButton.isBordered = false
        self.refreshButton.target = self
        self.refreshButton.action = #selector(self.refresh)
        self.refreshButton.translatesAutoresizingMaskIntoConstraints = false

        let settings = Self.symbolButton("gearshape", help: "设置")
        settings.target = self
        settings.action = #selector(self.showSettings)

        let quit = Self.symbolButton("power", help: "退出")
        quit.target = self
        quit.action = #selector(self.terminate)

        [self.refreshButton, settings, quit].forEach(container.addSubview)
        NSLayoutConstraint.activate([
            self.refreshButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            self.refreshButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            quit.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            quit.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            settings.trailingAnchor.constraint(equalTo: quit.leadingAnchor, constant: -7),
            settings.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    private func rebuildQuotaRows() {
        for view in self.quotaStack.arrangedSubviews {
            self.quotaStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        switch self.model.quotaState {
        case let .available(snapshot):
            self.quotaStack.isHidden = false
            for window in snapshot.windows {
                self.quotaStack.addArrangedSubview(QuotaRowView(window: window))
            }
            self.preferredContentSize = NSSize(
                width: 320,
                height: snapshot.windows.count > 1 ? 385 : 330)
        case .tokenOnly:
            self.quotaStack.isHidden = true
            self.preferredContentSize = NSSize(width: 320, height: 255)
        case .loading:
            self.quotaStack.isHidden = false
            self.quotaStack.addArrangedSubview(Self.quotaStatusRow("正在读取配额…"))
            self.preferredContentSize = NSSize(width: 320, height: 285)
        case let .failed(message):
            self.quotaStack.isHidden = false
            self.quotaStack.addArrangedSubview(Self.quotaStatusRow("配额暂不可用", detail: message))
            self.preferredContentSize = NSSize(width: 320, height: 300)
        }
    }

    private func updateActivity() {
        let active = self.model.isActivelyUpdating
        self.statusLabel.stringValue = "●  \(self.model.activityText)"
        self.statusLabel.textColor = active ? .systemGreen : .secondaryLabelColor
    }

    @objc
    private func refresh() {
        self.model.manualRefresh()
    }

    @objc
    private func showSettings() {
        self.openSettings()
    }

    @objc
    private func terminate() {
        self.quit()
    }

    private static func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints = false
        box.widthAnchor.constraint(equalToConstant: 288).isActive = true
        return box
    }

    private static func symbolButton(_ symbol: String, help: String) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: help)
        button.bezelStyle = .inline
        button.isBordered = false
        button.toolTip = help
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 18).isActive = true
        button.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return button
    }

    private static func quotaStatusRow(_ title: String, detail: String? = nil) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        stack.addArrangedSubview(label)
        if let detail {
            let detailLabel = NSTextField(wrappingLabelWithString: detail)
            detailLabel.font = .systemFont(ofSize: 10)
            detailLabel.textColor = .secondaryLabelColor
            detailLabel.maximumNumberOfLines = 2
            stack.addArrangedSubview(detailLabel)
        }
        stack.widthAnchor.constraint(equalToConstant: 288).isActive = true
        return stack
    }
}

@MainActor
private final class MetricTileView: NSView {
    private let valueLabel = NSTextField(labelWithString: "—")

    var value: String {
        get { self.valueLabel.stringValue }
        set { self.valueLabel.stringValue = newValue }
    }

    init(title: String) {
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 8
        self.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        self.valueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        self.valueLabel.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(titleLabel)
        self.addSubview(self.valueLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            self.valueLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            self.valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -8),
            self.valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
        ])
        self.updateBackground()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        self.updateBackground()
    }

    private func updateBackground() {
        let match = self.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        let color = match == .darkAqua
            ? NSColor(calibratedWhite: 0.22, alpha: 1)
            : NSColor(calibratedWhite: 0.94, alpha: 1)
        self.layer?.backgroundColor = color.cgColor
    }
}

@MainActor
private final class QuotaRowView: NSView {
    init(window: QuotaWindow) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalToConstant: 288).isActive = true

        let title = NSTextField(labelWithString: window.title)
        title.font = .systemFont(ofSize: 12, weight: .medium)
        title.translatesAutoresizingMaskIntoConstraints = false

        let percent = NSTextField(
            labelWithString: "\(Int(window.remainingPercent.rounded()))% 剩余")
        percent.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        percent.alignment = .right
        percent.translatesAutoresizingMaskIntoConstraints = false

        let tint: NSColor = if window.remainingPercent <= 5 {
            .systemRed
        } else if window.remainingPercent <= 20 {
            .systemOrange
        } else {
            .controlAccentColor
        }
        let bar = QuotaBarView(percent: window.remainingPercent, tint: tint)
        bar.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(title)
        self.addSubview(percent)
        self.addSubview(bar)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            title.topAnchor.constraint(equalTo: self.topAnchor),
            percent.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            percent.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            percent.leadingAnchor.constraint(greaterThanOrEqualTo: title.trailingAnchor, constant: 8),
            bar.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            bar.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 7),
            bar.heightAnchor.constraint(equalToConstant: 5),
        ])

        if let reset = window.resetsAt {
            let resetLabel = NSTextField(
                labelWithString: "重置：\(reset.formatted(date: .abbreviated, time: .shortened))")
            resetLabel.font = .systemFont(ofSize: 10)
            resetLabel.textColor = .secondaryLabelColor
            resetLabel.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(resetLabel)
            NSLayoutConstraint.activate([
                resetLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                resetLabel.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 5),
                resetLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            ])
        } else {
            bar.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
private final class QuotaBarView: NSView {
    private let percent: Double
    private let tint: NSColor

    init(percent: Double, tint: NSColor) {
        self.percent = min(100, max(0, percent))
        self.tint = tint
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        let track = NSBezierPath(roundedRect: self.bounds, xRadius: 2.5, yRadius: 2.5)
        NSColor.quaternaryLabelColor.withAlphaComponent(0.45).setFill()
        track.fill()

        let width = max(3, self.bounds.width * self.percent / 100)
        let fillRect = NSRect(x: 0, y: 0, width: width, height: self.bounds.height)
        let fill = NSBezierPath(roundedRect: fillRect, xRadius: 2.5, yRadius: 2.5)
        self.tint.setFill()
        fill.fill()
    }
}
