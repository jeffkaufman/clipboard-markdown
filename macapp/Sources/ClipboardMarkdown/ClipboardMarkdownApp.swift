import AppKit
import ClipboardKit
import SwiftUI

enum AppInfo {
    /// Taken from the bundle, so a dev build named differently is labelled
    /// correctly everywhere without a second place to edit.
    static let name = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
        ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
        ?? "Clipboard Markdown"

    /// The menu bar glyph.  A template image so it follows light and dark menu
    /// bars automatically.
    static var menuBarIcon: NSImage {
        let image = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png")
            .flatMap(NSImage.init(contentsOf:))
            ?? NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: name)
            ?? NSImage()
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }
}

@main
struct ClipboardMarkdownApp: App {
    var body: some Scene {
        MenuBarExtra {
            ForEach(Conversion.allCases, id: \.self) { conversion in
                Button(conversion.title) {
                    ClipboardService.run(conversion)
                }
            }

            Divider()

            Toggle("Launch at Login", isOn: Binding(
                get: { LoginItem.isEnabled },
                set: { LoginItem.setEnabled($0) }
            ))

            Divider()

            Button("Quit \(AppInfo.name)") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(nsImage: AppInfo.menuBarIcon)
        }
    }
}
