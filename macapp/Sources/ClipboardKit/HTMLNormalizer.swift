import Foundation
import SwiftSoup

/// Simplifies rich text down to basic structure and formatting.
///
/// This keeps the document's own markup and removes what does not belong,
/// rather than rebuilding the document by round-tripping it through Markdown.
/// The practical difference is that constructs Markdown cannot express survive:
/// underline, superscript and subscript, description lists, merged table cells,
/// and image alt text.
public enum HTMLNormalizer {

    public static func normalize(_ html: String) throws -> String {
        let document = try SwiftSoup.parseBodyFragment(html)
        try modernizeLegacyTags(in: document)
        try removeUnsupportedURLs(in: document)

        let cleaner = Cleaner(headWhitelist: nil, bodyWhitelist: try basicFormatting())
        let cleaned = try cleaner.clean(document)
        // Pretty-printing would reflow text into indented lines, and running
        // the result through again would reflow it further.  Leave whitespace
        // alone so normalizing twice is the same as normalizing once.
        cleaned.outputSettings(OutputSettings().prettyPrint(pretty: false))

        guard let body = cleaned.body() else { return "" }

        // The source's own indentation is not content.  Collapsing it keeps the
        // output readable, which matters because the plain-text flavor of the
        // clipboard carries this markup verbatim.
        collapseWhitespace(in: body, insidePre: false)
        try dropInsignificantWhitespace(in: body)
        trimBlockEdges(in: body)

        // Removing a <div> or <span> leaves its text loose in the parent, which
        // would merge into whatever paragraph you paste it into.  Give any such
        // run a paragraph of its own.
        try wrapLooseInlineContent(in: body)
        for quote in try body.select("blockquote") {
            try wrapLooseInlineContent(in: quote)
        }

        // An anchor stripped of its href is just noise around the text.
        for link in try body.select("a") where !link.hasAttr("href") {
            _ = try link.unwrap()
        }

        // Dropping an unsupported image can leave the paragraph that held it
        // with nothing in it, which would paste as a stray blank line.
        try pruneEmptyBlocks(in: body)

        // One top-level block per line.  Any newlines this adds are dropped
        // again by dropInsignificantWhitespace on a second pass, so normalizing
        // twice gives the same answer as normalizing once.
        return try body.getChildNodes()
            .map { try $0.outerHtml() }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// HTML renders any run of whitespace as a single space, so collapse them.
    /// `pre` is the exception, where the whitespace is the content.
    private static func collapseWhitespace(in parent: Element, insidePre: Bool) {
        for node in parent.getChildNodes() {
            if let text = node as? TextNode {
                guard !insidePre else { continue }
                let collapsed = text.getWholeText()
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                _ = text.text(collapsed)
            } else if let element = node as? Element {
                collapseWhitespace(
                    in: element, insidePre: insidePre || element.tagName() == "pre")
            }
        }
    }

    /// Blocks not worth keeping once they hold nothing at all.  `td` and `th`
    /// are deliberately absent: an empty cell still holds a table together.
    private static let prunableWhenEmpty: Set<String> = [
        "blockquote", "dd", "dl", "dt", "h1", "h2", "h3", "h4", "h5", "h6",
        "li", "ol", "p", "ul",
    ]

    private static func pruneEmptyBlocks(in element: Element) throws {
        for child in element.children() {
            try pruneEmptyBlocks(in: child)
        }
        guard prunableWhenEmpty.contains(element.tagName()),
              try element.text().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              // <img>, <br>, and <hr> are content even with no text of their own.
              try element.select("img, br, hr").size() == 0
        else { return }
        try element.remove()
    }

    /// Elements whose leading and trailing spaces are formatting, not content.
    private static let textBlocks: Set<String> = [
        "blockquote", "caption", "dd", "dt", "h1", "h2", "h3", "h4", "h5", "h6",
        "li", "p", "td", "th",
    ]

    private static func trimBlockEdges(in parent: Element) {
        if textBlocks.contains(parent.tagName()) {
            let children = parent.getChildNodes()
            if let first = children.first as? TextNode {
                _ = first.text(String(first.getWholeText().drop(while: { $0 == " " })))
            }
            if let last = children.last as? TextNode {
                var text = last.getWholeText()
                while text.hasSuffix(" ") { text.removeLast() }
                _ = last.text(text)
            }
        }
        for child in parent.children() where child.tagName() != "pre" {
            trimBlockEdges(in: child)
        }
    }

    /// Containers that hold only other elements, so whitespace between their
    /// children is formatting rather than content.
    private static let whitespaceOnlyContainers: Set<String> = [
        "blockquote", "body", "dl", "ol", "table", "tbody", "tfoot", "thead",
        "tr", "ul",
    ]

    private static func dropInsignificantWhitespace(in parent: Element) throws {
        if whitespaceOnlyContainers.contains(parent.tagName()) {
            for node in parent.getChildNodes() {
                guard let text = node as? TextNode, !hasVisibleContent(text) else { continue }
                try text.remove()
            }
        }
        for child in parent.children() where child.tagName() != "pre" {
            try dropInsignificantWhitespace(in: child)
        }
    }

    /// What survives: structure, emphasis, links, images, lists, and tables.
    ///
    /// Dropped along with everything not listed: `div` and `span`, whose only
    /// job in clipboard HTML is carrying styles, and presentational attributes
    /// such as `width`, `height`, and `align`.  URL schemes are filtered
    /// separately, in removeUnsupportedURLs.
    private static func basicFormatting() throws -> Whitelist {
        try Whitelist.none()
            .addTags(
                "a", "blockquote", "br", "caption", "cite", "code", "dd", "del",
                "dl", "dt", "em", "h1", "h2", "h3", "h4", "h5", "h6", "hr", "img",
                "ins", "li", "ol", "p", "pre", "strong", "sub", "sup", "table",
                "tbody", "td", "tfoot", "th", "thead", "tr", "u", "ul"
            )
            .addAttributes("a", "href", "title")
            .addAttributes("img", "alt", "src", "title")
            .addAttributes("ol", "start")
            .addAttributes("td", "colspan", "rowspan")
            .addAttributes("th", "colspan", "rowspan", "scope")
    }

    private static func removeUnsupportedURLs(in document: Document) throws {
        for link in try document.select("a[href]")
        where !URLSchemes.isAllowed(try link.attr("href"), schemes: URLSchemes.links) {
            try link.removeAttr("href")
        }
        // An image whose source we dropped has nothing left to show.
        for image in try document.select("img[src]")
        where !URLSchemes.isAllowed(try image.attr("src"), schemes: URLSchemes.images) {
            try image.remove()
        }
    }

    /// Old editors still emit these; normalizing them keeps the output uniform.
    private static let legacyEquivalents = [
        "b": "strong", "i": "em", "strike": "del",
    ]

    private static func modernizeLegacyTags(in document: Document) throws {
        for (old, new) in legacyEquivalents {
            for element in try document.select(old) {
                try element.tagName(new)
            }
        }
    }

    private static let blockTags: Set<String> = [
        "blockquote", "caption", "dd", "dl", "dt", "h1", "h2", "h3", "h4", "h5",
        "h6", "hr", "li", "ol", "p", "pre", "table", "tbody", "td", "tfoot",
        "th", "thead", "tr", "ul",
    ]

    private static func wrapLooseInlineContent(in parent: Element) throws {
        var run: [Node] = []

        func flush() throws {
            defer { run = [] }
            guard let first = run.first, run.contains(where: hasVisibleContent) else { return }
            let paragraph = try Element(Tag.valueOf("p"), "")
            _ = try first.before(paragraph)
            for node in run {
                try node.remove()
                _ = try paragraph.appendChild(node)
            }
        }

        for node in parent.getChildNodes() {
            if let element = node as? Element, blockTags.contains(element.tagName()) {
                try flush()
            } else {
                run.append(node)
            }
        }
        try flush()
    }

    private static func hasVisibleContent(_ node: Node) -> Bool {
        guard let text = node as? TextNode else { return true }
        return !text.getWholeText().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
