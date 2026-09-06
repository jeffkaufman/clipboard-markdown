import Foundation

/// The three conversions the app offers.
public enum Conversion: String, CaseIterable, Sendable {
    /// Rich text in, simplified rich text out.
    case normalize
    /// Rich text in, Markdown as plain text out.
    case markdownify
    /// Markdown as plain text in, rich text out.
    case htmlify

    public var title: String {
        switch self {
        case .normalize: return "Normalize Clipboard"
        case .markdownify: return "Convert Clipboard to Markdown"
        case .htmlify: return "Convert Clipboard to HTML"
        }
    }
}

public enum ClipboardConversions {

    /// Strips a document down to basic structure and formatting: colors, fonts,
    /// sizes, and the rest of the styling go away, while bold, italic, links,
    /// lists, and tables survive.
    public static func normalize(html: String) throws -> String {
        try HTMLNormalizer.normalize(html)
    }

    public static func markdownify(html: String) throws -> String {
        try HTMLToMarkdown.convert(html)
    }

    /// Markdown allows raw HTML to pass straight through, and swift-markdown's
    /// formatter neither escapes it nor filters link destinations.  Normalizing
    /// the result puts it through the same allowlist as everything else, so a
    /// `<script>` or a `javascript:` link in the source Markdown cannot reach
    /// the clipboard as live markup.
    public static func htmlify(markdown: String) throws -> String {
        try HTMLNormalizer.normalize(MarkdownToHTML.convert(markdown))
    }
}
