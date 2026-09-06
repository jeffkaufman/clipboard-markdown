import AppKit

/// Reading and writing the flavors of the clipboard we care about.
enum Pasteboard {

    /// Bumps whenever anything is put on the clipboard, so we can tell whether
    /// it changed while a conversion was running.
    static var changeCount: Int {
        NSPasteboard.general.changeCount
    }

    /// Rich text from the clipboard as an HTML string.
    ///
    /// Browsers and most editors offer `public.html` directly.  Some apps
    /// (TextEdit, Pages, Notes) offer only RTF, so fall back to converting
    /// that, which keeps the app useful outside the browser.
    static func readHTML() -> String? {
        let pasteboard = NSPasteboard.general

        if let html = pasteboard.string(forType: .html), !html.isEmpty {
            return html
        }

        if let rtf = pasteboard.data(forType: .rtf),
           let attributed = NSAttributedString(rtf: rtf, documentAttributes: nil) {
            let range = NSRange(location: 0, length: attributed.length)
            if let data = try? attributed.data(
                from: range,
                documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
            ) {
                return String(data: data, encoding: .utf8)
            }
        }

        return nil
    }

    static func readPlainText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    /// Writes rich text.  The plain-text flavor is the HTML source, matching
    /// what the original `html-clipboard set` did, so that pasting into a code
    /// editor gives you the markup.
    static func writeHTML(_ html: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(html, forType: .html)
        pasteboard.setString(html, forType: .string)
    }

    static func writePlainText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
