import AppKit

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let model: AppModel
    private let settings: AppSettings
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var popoverController: TokenPopoverViewController?
    private var settingsWindow: SettingsWindowController?

    init(model: AppModel, settings: AppSettings) {
        self.model = model
        self.settings = settings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        self.statusItem.autosaveName = "tokenbar-for-codex"
        if let button = self.statusItem.button {
            button.target = self
            button.action = #selector(self.togglePopover)
            button.sendAction(on: [.leftMouseDown])
            button.image = nil
            button.imagePosition = .noImage
        }

        self.popover.behavior = .transient
        self.popover.animates = true
        self.popover.delegate = self
        self.model.onChange = { [weak self] in
            self?.refreshUI()
        }
        self.settings.onChange = { [weak self] in
            self?.refreshUI()
        }
        self.refreshUI()
    }

    @objc
    private func togglePopover() {
        guard let button = self.statusItem.button else { return }
        if self.popover.isShown {
            self.popover.performClose(nil)
        } else {
            self.preparePopover()
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func popoverWillShow(_ notification: Notification) {
        self.statusItem.button?.highlight(true)
    }

    func popoverDidClose(_ notification: Notification) {
        self.statusItem.button?.highlight(false)
        self.popover.contentViewController = nil
        self.popoverController = nil
    }

    private func preparePopover() {
        guard self.popoverController == nil else {
            self.popoverController?.update()
            return
        }
        let controller = TokenPopoverViewController(
            model: self.model,
            openSettings: { [weak self] in
                self?.popover.performClose(nil)
                self?.showSettings()
            },
            quit: {
                NSApp.terminate(nil)
            })
        self.popoverController = controller
        self.popover.contentViewController = controller
        controller.update()
    }

    private func showSettings() {
        if self.settingsWindow == nil {
            self.settingsWindow = SettingsWindowController(settings: self.settings)
        }
        self.settingsWindow?.present()
    }

    private func refreshUI() {
        self.renderStatusItem(
            token: self.model.tokenSnapshot,
            quota: self.model.quotaState.snapshot,
            style: self.settings.menuBarStyle,
            useWarningColor: self.settings.useWarningColor)
        self.popoverController?.update()
    }

    private func renderStatusItem(
        token: LiveTokenSnapshot?,
        quota: QuotaSnapshot?,
        style: AppSettings.MenuBarStyle,
        useWarningColor: Bool)
    {
        guard let button = self.statusItem.button else { return }
        let tokenText = token.map { CompactNumber.string($0.current.total) } ?? "—"
        let remaining = quota?.displayWindow?.remainingPercent
        let quotaText = remaining.map { "\(Int($0.rounded()))%" }
        let quotaColor = self.quotaColor(remaining, enabled: useWarningColor)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byClipping

        let attributed = NSMutableAttributedString()
        switch (style, quotaText) {
        case (_, nil):
            attributed.append(NSAttributedString(
                string: tokenText,
                attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: paragraph,
                ]))
        case let (.twoLines, quotaText?):
            paragraph.minimumLineHeight = 10
            paragraph.maximumLineHeight = 10
            attributed.append(NSAttributedString(
                string: tokenText,
                attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold),
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: paragraph,
                ]))
            attributed.append(NSAttributedString(
                string: "\n\(quotaText)",
                attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold),
                    .foregroundColor: quotaColor,
                    .paragraphStyle: paragraph,
                ]))
        case let (.oneLine, quotaText?):
            attributed.append(NSAttributedString(
                string: "\(tokenText) · ",
                attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: paragraph,
                ]))
            attributed.append(NSAttributedString(
                string: quotaText,
                attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
                    .foregroundColor: quotaColor,
                    .paragraphStyle: paragraph,
                ]))
        }

        button.attributedTitle = attributed
        let bounds = attributed.boundingRect(
            with: NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading])
        self.statusItem.length = max(40, ceil(bounds.width) + 9)
        if let quotaText {
            button.setAccessibilityTitle("当前 \(tokenText) tokens，配额剩余 \(quotaText)")
        } else {
            button.setAccessibilityTitle("当前 \(tokenText) tokens")
        }
    }

    private func quotaColor(_ remaining: Double?, enabled: Bool) -> NSColor {
        guard enabled, let remaining else { return .labelColor }
        if remaining <= 5 {
            return .systemRed
        }
        if remaining <= 20 {
            return .systemOrange
        }
        return .labelColor
    }
}
