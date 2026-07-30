import AppKit

@MainActor
final class SettingsViewController: NSViewController {
    private let settings: AppSettings
    private let styleControl = NSSegmentedControl(
        labels: ["双行", "单行"],
        trackingMode: .selectOne,
        target: nil,
        action: nil)
    private let warningCheck = NSButton(checkboxWithTitle: "配额较低时显示警告颜色", target: nil, action: nil)
    private let loginCheck = NSButton(checkboxWithTitle: "登录时自动启动", target: nil, action: nil)
    private let errorLabel = NSTextField(wrappingLabelWithString: "")

    init(settings: AppSettings) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let root = NSView()
        self.view = root

        let title = NSTextField(labelWithString: "TokenBar 设置")
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        let subtitle = NSTextField(labelWithString: "只保留实时 token 与 Codex 配额。")
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .secondaryLabelColor

        let styleTitle = NSTextField(labelWithString: "菜单栏样式")
        styleTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        self.styleControl.target = self
        self.styleControl.action = #selector(self.styleChanged)
        self.styleControl.segmentStyle = .rounded

        self.warningCheck.target = self
        self.warningCheck.action = #selector(self.warningChanged)

        let launchTitle = NSTextField(labelWithString: "启动")
        launchTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        self.loginCheck.target = self
        self.loginCheck.action = #selector(self.loginChanged)

        self.errorLabel.font = .systemFont(ofSize: 10)
        self.errorLabel.textColor = .systemRed
        self.errorLabel.maximumNumberOfLines = 2

        let privacy = self.makePrivacyBox()
        let stack = NSStackView(views: [
            title,
            subtitle,
            Self.spacer(8),
            styleTitle,
            self.styleControl,
            self.warningCheck,
            Self.spacer(7),
            launchTitle,
            self.loginCheck,
            self.errorLabel,
            Self.spacer(7),
            privacy,
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 7
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 20),
            self.styleControl.widthAnchor.constraint(equalToConstant: 150),
            privacy.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
        self.updateControls()
    }

    private func makePrivacyBox() -> NSView {
        let box = NSView()
        box.wantsLayer = true
        box.layer?.cornerRadius = 10
        box.layer?.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.3).cgColor
        box.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: "◉  本地优先")
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false

        let detail = NSTextField(
            wrappingLabelWithString:
            "对话内容不会上传。Token 只从 ~/.codex 的本地事件读取；配额通过 Codex 自带的只读服务刷新。")
        detail.font = .systemFont(ofSize: 11)
        detail.textColor = .secondaryLabelColor
        detail.maximumNumberOfLines = 3
        detail.translatesAutoresizingMaskIntoConstraints = false

        box.addSubview(title)
        box.addSubview(detail)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -12),
            title.topAnchor.constraint(equalTo: box.topAnchor, constant: 11),
            detail.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
            detail.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -12),
            detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5),
            detail.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -11),
        ])
        return box
    }

    private func updateControls() {
        self.styleControl.selectedSegment = self.settings.menuBarStyle == .twoLines ? 0 : 1
        self.warningCheck.state = self.settings.useWarningColor ? .on : .off
        self.loginCheck.state = self.settings.launchAtLoginEnabled ? .on : .off
        self.errorLabel.stringValue = self.settings.launchAtLoginError ?? ""
        self.errorLabel.isHidden = self.errorLabel.stringValue.isEmpty
    }

    @objc
    private func styleChanged() {
        self.settings.menuBarStyle = self.styleControl.selectedSegment == 0 ? .twoLines : .oneLine
    }

    @objc
    private func warningChanged() {
        self.settings.useWarningColor = self.warningCheck.state == .on
    }

    @objc
    private func loginChanged() {
        self.settings.setLaunchAtLogin(self.loginCheck.state == .on)
        self.updateControls()
    }

    private static func spacer(_ height: CGFloat) -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }
}
