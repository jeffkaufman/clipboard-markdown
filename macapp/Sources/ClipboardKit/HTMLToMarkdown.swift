import Foundation
import SwiftSoup

/// Converts clipboard HTML into GitHub Flavored Markdown.
public enum HTMLToMarkdown {
    public static func convert(_ html: String) throws -> String {
        let document = try SwiftSoup.parse(html)
        let root: Element = document.body() ?? document
        let renderer = Renderer()
        let text = renderer.join(try renderer.blocks(of: root), tightLists: false)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : trimmed + "\n"
    }
}

/// A rendered block, tagged so that a list nested inside a list item can hug
/// the line above it instead of getting a blank line.
private struct Block {
    let text: String
    let isList: Bool
}

private final class Renderer {

    /// Elements that break the flow of inline text.
    static let blockTags: Set<String> = [
        "address", "article", "aside", "blockquote", "dd", "details", "div",
        "dl", "dt", "fieldset", "figcaption", "figure", "footer", "form",
        "h1", "h2", "h3", "h4", "h5", "h6", "header", "hr", "li", "main",
        "nav", "ol", "p", "pre", "section", "summary", "table", "tbody",
        "td", "tfoot", "th", "thead", "tr", "ul",
    ]

    /// Elements whose contents are not visible text.
    static let skipTags: Set<String> = [
        "head", "link", "meta", "noscript", "script", "style", "template", "title",
    ]

    // MARK: - Blocks

    func blocks(of container: Element) throws -> [Block] {
        var result: [Block] = []
        var inlineBuffer = ""

        func flushInline() {
            let text = Self.normalizeInline(inlineBuffer)
            inlineBuffer = ""
            guard !text.isEmpty else { return }
            result.append(Block(text: Self.escapeLeadingMarkers(text), isList: false))
        }

        for node in container.getChildNodes() {
            if let element = node as? Element {
                let tag = element.tagName()
                if Self.skipTags.contains(tag) { continue }
                if Self.blockTags.contains(tag) {
                    flushInline()
                    result.append(contentsOf: try blockContent(of: element))
                    continue
                }
            }
            inlineBuffer += try renderNode(node)
        }
        flushInline()
        return result
    }

    private func blockContent(of element: Element) throws -> [Block] {
        switch element.tagName() {
        case "h1", "h2", "h3", "h4", "h5", "h6":
            let level = Int(String(element.tagName().dropFirst())) ?? 1
            let text = try inlineText(of: element)
            guard !text.isEmpty else { return [] }
            let hashes = String(repeating: "#", count: level)
            // Headings are a single line: fold any hard breaks back to spaces.
            let oneLine = text.replacingOccurrences(of: "  \n", with: " ")
            return [Block(text: "\(hashes) \(oneLine)", isList: false)]

        case "hr":
            return [Block(text: "---", isList: false)]

        case "pre":
            return [try codeBlock(of: element)]

        case "blockquote":
            let inner = join(try blocks(of: element), tightLists: false)
            guard !inner.isEmpty else { return [] }
            let quoted = inner.split(separator: "\n", omittingEmptySubsequences: false)
                .map { $0.isEmpty ? ">" : "> " + $0 }
                .joined(separator: "\n")
            return [Block(text: quoted, isList: false)]

        case "ul":
            let list = try renderList(element, ordered: false)
            return list.isEmpty ? [] : [Block(text: list, isList: true)]

        case "ol":
            let list = try renderList(element, ordered: true)
            return list.isEmpty ? [] : [Block(text: list, isList: true)]

        case "table":
            let table = try renderTable(element)
            return table.isEmpty ? [] : [Block(text: table, isList: false)]

        default:
            // p, div, section, details, summary, li reached out of context, and
            // anything else we do not have special handling for: transparent.
            let children = try blocks(of: element)
            if !children.isEmpty { return children }
            let text = try inlineText(of: element)
            guard !text.isEmpty else { return [] }
            return [Block(text: Self.escapeLeadingMarkers(text), isList: false)]
        }
    }

    func join(_ blocks: [Block], tightLists: Bool) -> String {
        var out = ""
        for (index, block) in blocks.enumerated() {
            if index > 0 {
                out += (tightLists && block.isList) ? "\n" : "\n\n"
            }
            out += block.text
        }
        return out
    }

    // MARK: - Lists

    private func renderList(_ element: Element, ordered: Bool) throws -> String {
        var lines: [String] = []
        var number = 1
        if ordered, let start = Int(try element.attr("start")) {
            number = start
        }

        for item in element.children() where item.tagName() == "li" {
            let marker = ordered ? "\(number). " : "- "
            number += 1
            let indent = String(repeating: " ", count: marker.count)
            let body = join(try blocks(of: item), tightLists: true)

            if body.isEmpty {
                lines.append(String(marker.dropLast()))
                continue
            }

            let bodyLines = body.split(separator: "\n", omittingEmptySubsequences: false)
            for (index, line) in bodyLines.enumerated() {
                if index == 0 {
                    lines.append(marker + line)
                } else {
                    lines.append(line.isEmpty ? "" : indent + line)
                }
            }
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Tables

    private func renderTable(_ table: Element) throws -> String {
        var header: [String]?
        var body: [[String]] = []
        var alignments: [String] = []

        for row in Self.directRows(of: table) {
            var cells: [String] = []
            var rowAlignments: [String] = []
            var sawHeaderCell = false

            for cell in row.children() where cell.tagName() == "td" || cell.tagName() == "th" {
                if cell.tagName() == "th" { sawHeaderCell = true }
                let text = try inlineText(of: cell, inTableCell: true)
                // A cell cannot span lines in GFM.
                cells.append(text.replacingOccurrences(of: "  \n", with: " ")
                    .replacingOccurrences(of: "\n", with: " "))
                rowAlignments.append(try Self.alignment(of: cell))
            }

            guard !cells.isEmpty else { continue }
            if header == nil && sawHeaderCell {
                header = cells
                alignments = rowAlignments
            } else {
                body.append(cells)
            }
        }

        // GFM has no headerless table, so promote the first row if we must.
        if header == nil {
            guard !body.isEmpty else { return "" }
            header = body.removeFirst()
            alignments = Array(repeating: "", count: header!.count)
        }
        guard let headerCells = header else { return "" }

        let columnCount = max(headerCells.count, body.map(\.count).max() ?? 0)
        func padRow(_ row: [String]) -> [String] {
            row + Array(repeating: "", count: max(0, columnCount - row.count))
        }
        while alignments.count < columnCount { alignments.append("") }

        var widths = [Int](repeating: 3, count: columnCount)
        for row in [padRow(headerCells)] + body.map(padRow) {
            for (index, cell) in row.enumerated() {
                widths[index] = max(widths[index], cell.count)
            }
        }

        func line(_ row: [String]) -> String {
            let cells = padRow(row).enumerated().map { index, cell in
                cell + String(repeating: " ", count: widths[index] - cell.count)
            }
            return "| " + cells.joined(separator: " | ") + " |"
        }

        var separator: [String] = []
        for index in 0..<columnCount {
            let width = widths[index]
            switch alignments[index] {
            case "center":
                separator.append(":" + String(repeating: "-", count: width) + ":")
            case "right":
                separator.append(String(repeating: "-", count: width + 1) + ":")
            case "left":
                separator.append(":" + String(repeating: "-", count: width + 1))
            default:
                separator.append(String(repeating: "-", count: width + 2))
            }
        }

        var rows = [line(headerCells), "|" + separator.joined(separator: "|") + "|"]
        rows.append(contentsOf: body.map(line))
        return rows.joined(separator: "\n")
    }

    /// The table's own rows.  A `select("tr")` would also pull in the rows of
    /// any nested table, which Markdown cannot represent anyway, and would
    /// emit their contents twice.
    private static func directRows(of table: Element) -> [Element] {
        var rows: [Element] = []
        for child in table.children() {
            switch child.tagName() {
            case "tr":
                rows.append(child)
            case "thead", "tbody", "tfoot":
                rows.append(contentsOf: child.children().filter { $0.tagName() == "tr" })
            default:
                break
            }
        }
        return rows
    }

    private static func alignment(of cell: Element) throws -> String {
        let attr = try cell.attr("align").lowercased()
        if ["left", "right", "center"].contains(attr) { return attr }
        let style = try cell.attr("style").lowercased()
        for value in ["center", "right", "left"] where style.contains("text-align: \(value)")
            || style.contains("text-align:\(value)") {
            return value
        }
        return ""
    }

    // MARK: - Code

    private func codeBlock(of element: Element) throws -> Block {
        let code = Self.rawText(of: element)
        var language = ""
        if let codeElement = try element.select("code").first() {
            let classes = try codeElement.attr("class").split(separator: " ")
            for name in classes where name.hasPrefix("language-") {
                language = String(name.dropFirst("language-".count))
                break
            }
        }
        // Use a fence long enough to survive backticks in the content.
        var fenceLength = 3
        for run in code.components(separatedBy: CharacterSet(charactersIn: "`").inverted) {
            fenceLength = max(fenceLength, run.count + 1)
        }
        let fence = String(repeating: "`", count: fenceLength)
        let trimmed = code.trimmingCharacters(in: .newlines)
        return Block(text: "\(fence)\(language)\n\(trimmed)\n\(fence)", isList: false)
    }

    // MARK: - Inline

    func inlineText(of element: Element, inTableCell: Bool = false) throws -> String {
        var buffer = ""
        for node in element.getChildNodes() {
            buffer += try renderNode(node, inTableCell: inTableCell)
        }
        return Self.normalizeInline(buffer)
    }

    private func renderNode(_ node: Node, inTableCell: Bool = false) throws -> String {
        if let text = node as? TextNode {
            let collapsed = Self.collapseWhitespace(text.getWholeText())
            return MarkdownEscaping.escape(collapsed, inTableCell: inTableCell)
        }
        guard let element = node as? Element else { return "" }

        let tag = element.tagName()
        if Self.skipTags.contains(tag) { return "" }

        func inner() throws -> String {
            var buffer = ""
            for child in element.getChildNodes() {
                buffer += try renderNode(child, inTableCell: inTableCell)
            }
            return buffer
        }

        switch tag {
        case "br":
            return "\n"

        case "strong", "b":
            return Self.wrap(try inner(), in: "**")

        case "em", "i", "u", "cite", "var":
            return Self.wrap(try inner(), in: "*")

        case "del", "s", "strike":
            return Self.wrap(try inner(), in: "~~")

        case "code", "kbd", "samp", "tt":
            let raw = Self.collapseWhitespace(Self.rawText(of: element))
                .trimmingCharacters(in: .whitespaces)
            guard !raw.isEmpty else { return "" }
            var ticks = 1
            for run in raw.components(separatedBy: CharacterSet(charactersIn: "`").inverted) {
                ticks = max(ticks, run.count + 1)
            }
            let fence = String(repeating: "`", count: ticks)
            let pad = raw.hasPrefix("`") || raw.hasSuffix("`") ? " " : ""
            return fence + pad + raw + pad + fence

        case "a":
            let text = try inner()
            let href = try element.attr("href").trimmingCharacters(in: .whitespacesAndNewlines)
            // Same scheme rules as normalizing, so markdownifying a hostile
            // page cannot decode an obfuscated javascript: URL into a working
            // one that "Convert to HTML" would then make live.
            guard !href.isEmpty,
                  URLSchemes.isAllowed(href, schemes: URLSchemes.links)
            else { return text }
            let label = text.trimmingCharacters(in: .whitespaces)
            guard !label.isEmpty else { return text }
            let lead = text.hasPrefix(" ") ? " " : ""
            let trail = text.hasSuffix(" ") ? " " : ""
            return "\(lead)[\(label)](\(Self.encodeURL(href)))\(trail)"

        case "img":
            let src = try element.attr("src").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !src.isEmpty,
                  URLSchemes.isAllowed(src, schemes: URLSchemes.images)
            else { return "" }
            let alt = MarkdownEscaping.escape(try element.attr("alt"), inTableCell: inTableCell)
            return "![\(alt)](\(Self.encodeURL(src)))"

        case "sup":
            if let mapped = Self.transliterate(try element.text(), using: Self.superscripts) {
                return mapped
            }
            return try inner()

        case "sub":
            if let mapped = Self.transliterate(try element.text(), using: Self.subscripts) {
                return mapped
            }
            return try inner()

        default:
            return try inner()
        }
    }

    // MARK: - Text helpers

    /// Wraps inline content in emphasis markers, moving any surrounding spaces
    /// outside them so `** bold **` never happens.
    private static func wrap(_ text: String, in marker: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return text }
        let lead = text.hasPrefix(" ") ? " " : ""
        let trail = text.hasSuffix(" ") ? " " : ""
        return lead + marker + trimmed + marker + trail
    }

    /// HTML collapses all runs of whitespace, newlines included, to one space.
    private static func collapseWhitespace(_ text: String) -> String {
        var out = ""
        var lastWasSpace = false
        for ch in text {
            if ch.isWhitespace {
                if !lastWasSpace { out.append(" ") }
                lastWasSpace = true
            } else {
                out.append(ch)
                lastWasSpace = false
            }
        }
        return out
    }

    /// Tidies an assembled inline run and turns `<br>` newlines into Markdown
    /// hard breaks.
    private static func normalizeInline(_ text: String) -> String {
        var out = text.replacingOccurrences(
            of: "[ \\t]+", with: " ", options: .regularExpression)
        out = out.replacingOccurrences(
            of: " *\n *", with: "\n", options: .regularExpression)
        out = out.trimmingCharacters(in: .whitespacesAndNewlines)
        return out.replacingOccurrences(of: "\n", with: "  \n")
    }

    private static func escapeLeadingMarkers(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { MarkdownEscaping.escapeLeadingBlockMarker(String($0)) }
            .joined(separator: "\n")
    }

    /// Text content with whitespace left exactly as authored.
    private static func rawText(of element: Element) -> String {
        var out = ""
        for node in element.getChildNodes() {
            if let text = node as? TextNode {
                out += text.getWholeText()
            } else if let child = node as? Element {
                out += rawText(of: child)
            } else if let data = node as? DataNode {
                out += data.getWholeData()
            }
        }
        return out
    }

    private static func encodeURL(_ url: String) -> String {
        if url.contains(" ") || url.contains("(") || url.contains(")") {
            return "<" + url + ">"
        }
        return url
    }

    private static let superscripts: [Character: Character] = [
        "0": "\u{2070}", "1": "\u{00B9}", "2": "\u{00B2}", "3": "\u{00B3}",
        "4": "\u{2074}", "5": "\u{2075}", "6": "\u{2076}", "7": "\u{2077}",
        "8": "\u{2078}", "9": "\u{2079}", "+": "\u{207A}", "-": "\u{207B}",
        "=": "\u{207C}", "(": "\u{207D}", ")": "\u{207E}", "n": "\u{207F}",
        "i": "\u{2071}",
    ]

    private static let subscripts: [Character: Character] = [
        "0": "\u{2080}", "1": "\u{2081}", "2": "\u{2082}", "3": "\u{2083}",
        "4": "\u{2084}", "5": "\u{2085}", "6": "\u{2086}", "7": "\u{2087}",
        "8": "\u{2088}", "9": "\u{2089}", "+": "\u{208A}", "-": "\u{208B}",
        "=": "\u{208C}", "(": "\u{208D}", ")": "\u{208E}", "a": "\u{2090}",
        "e": "\u{2091}", "o": "\u{2092}", "x": "\u{2093}",
    ]

    /// Maps to Unicode super/subscripts, or gives up if any character has no
    /// equivalent (a half-converted "H²O₃x" is worse than plain text).
    private static func transliterate(
        _ text: String, using table: [Character: Character]
    ) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        var out = ""
        for ch in trimmed {
            guard let mapped = table[ch] else { return nil }
            out.append(mapped)
        }
        return out
    }
}
