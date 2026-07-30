import AppKit

@MainActor
final class SettingsWindowController: NSWindowController {
    init(settings: AppSettings) {
        let controller = SettingsViewController(settings: settings)
        let window = NSWindow(contentViewController: controller)
        window.title = "TokenBar 设置"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 420, height: 365))
        window.center()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        self.window?.center()
        self.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window?.makeKeyAndOrderFront(nil)
    }
}
