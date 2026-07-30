import AppKit

@main
enum TokenBarApplication {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        #if DEBUG
        let isQAPreview = CommandLine.arguments.contains("--qa-window")
        application.setActivationPolicy(isQAPreview ? .regular : .accessory)
        #else
        application.setActivationPolicy(.accessory)
        #endif
        application.delegate = delegate
        application.run()
        withExtendedLifetime(delegate) {}
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var settings: AppSettings?
    private var statusBarController: StatusBarController?
    #if DEBUG
    private var previewWindow: NSWindow?
    #endif

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = AppSettings()
        let model = AppModel()
        self.settings = settings
        self.model = model
        self.statusBarController = StatusBarController(model: model, settings: settings)

        #if DEBUG
        let isQAPreview = CommandLine.arguments.contains("--qa-window")
        if isQAPreview {
            model.loadQAPreviewData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self, weak model] in
                guard let self, let model else { return }
                let controller = TokenPopoverViewController(
                    model: model,
                    openSettings: {},
                    quit: {})
                controller.loadView()
                controller.update()
                let existingChangeHandler = model.onChange
                model.onChange = { [weak controller] in
                    existingChangeHandler?()
                    controller?.update()
                }
                let window = NSWindow(contentViewController: controller)
                window.title = "TokenBar for Codex"
                window.styleMask = [.titled, .closable, .miniaturizable]
                window.setContentSize(controller.preferredContentSize)
                window.center()
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                self.previewWindow = window
            }
        } else {
            model.start()
        }
        #else
        model.start()
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        self.model?.stop()
    }
}
