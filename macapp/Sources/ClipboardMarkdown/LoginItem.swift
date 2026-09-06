import AppKit
import ServiceManagement

/// Launch-at-login, via the sandbox-friendly ServiceManagement API.  The old
/// Platypus apps needed a manual trip through System Settings, and only one of
/// the two would stick.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = enabled
                ? "Could not add \(AppInfo.name) to your login items."
                : "Could not remove \(AppInfo.name) from your login items."
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
