import Foundation
import ServiceManagement

@MainActor
final class AppSettings {
    enum MenuBarStyle: String, CaseIterable, Identifiable {
        case twoLines
        case oneLine

        var id: String { self.rawValue }

        var title: String {
            switch self {
            case .twoLines:
                "双行"
            case .oneLine:
                "单行"
            }
        }
    }

    var menuBarStyle: MenuBarStyle {
        didSet {
            UserDefaults.standard.set(self.menuBarStyle.rawValue, forKey: "menuBarStyle")
            self.onChange?()
        }
    }

    var useWarningColor: Bool {
        didSet {
            UserDefaults.standard.set(self.useWarningColor, forKey: "useWarningColor")
            self.onChange?()
        }
    }

    private(set) var launchAtLoginEnabled: Bool
    private(set) var launchAtLoginError: String?
    var onChange: (() -> Void)?

    init() {
        self.menuBarStyle = MenuBarStyle(
            rawValue: UserDefaults.standard.string(forKey: "menuBarStyle") ?? "") ?? .twoLines
        self.useWarningColor = UserDefaults.standard.object(forKey: "useWarningColor") as? Bool ?? true
        self.launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            self.launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            self.launchAtLoginError = nil
        } catch {
            self.launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            self.launchAtLoginError = error.localizedDescription
        }
        self.onChange?()
    }
}
