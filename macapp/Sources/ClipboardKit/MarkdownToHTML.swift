import Foundation
import Markdown
import SwiftSoup

/// Converts Markdown into HTML, via swift-markdown (cmark-gfm), so tables,
/// strikethrough, and the rest of GFM come along.
public enum MarkdownToHTML {
    public static func convert(_ markdown: String) -> String {
        let document = Document(parsing: markdown, options: [])
        var formatter = HTMLFormatter()
        formatter.visit(document)
        let html = formatter.result.trimmingCharacters(in: .whitespacesAndNewlines)
        return tightenListItems(html)
    }

    /// swift-markdown's AST does not record whether a list was tight, so its
    /// formatter always wraps list items in `<p>`, which pastes with an extra
    /// blank line between every bullet.  Unwrap the paragraph in items that
    /// hold just one, which is what a tight list means in practice.
    private static func tightenListItems(_ html: String) -> String {
        guard let document = try? SwiftSoup.parseBodyFragment(html) else { return html }
        document.outputSettings(OutputSettings().prettyPrint(pretty: false))

        guard let items = try? document.select("li") else { return html }
        for item in items {
            let paragraphs = item.children().filter { $0.tagName() == "p" }
            guard paragraphs.count == 1 else { continue }
            _ = try? paragraphs[0].unwrap()
        }

        guard let body = document.body(), let result = try? body.html() else { return html }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
