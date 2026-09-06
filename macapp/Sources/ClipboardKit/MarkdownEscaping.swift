import Foundation

/// Escaping rules for text that becomes Markdown.
///
/// A strict Markdown writer escapes every character that could possibly be
/// syntax, which makes the output unpleasant to read and to paste into an LLM:
/// `file\_name`, `\[1\]`, `3 \* 4`.  Rather than escaping everything and then
/// unescaping heuristically (what bin/unescape-markdown does to pandoc's
/// output), we escape only where the character would actually be read as
/// syntax:
///
/// - `$`, `|`, `[`, `]` are left alone.  Pipes are escaped inside table cells,
///   where they really would end the cell.
/// - `_` is escaped only in an emphasis-capable position, meaning exactly one
///   side of it is a word character.  So `file_name` and `foo _ bar` survive
///   intact, while `_italic_` stays escaped.
/// - `*` is escaped unless it has whitespace on both sides, so `3 * 4` survives
///   but `*bold*` stays escaped.
/// - Backslash and backtick are always escaped.
enum MarkdownEscaping {
    /// Escapes inline text.  `inTableCell` additionally escapes pipes.
    static func escape(_ text: String, inTableCell: Bool = false) -> String {
        var out = ""
        out.reserveCapacity(text.count)
        let chars = Array(text)

        for (i, ch) in chars.enumerated() {
            let before = i > 0 ? chars[i - 1] : nil
            let after = i + 1 < chars.count ? chars[i + 1] : nil

            switch ch {
            case "\\", "`":
                out.append("\\")
                out.append(ch)
            case "_":
                // Emphasis needs a word character on exactly one side.
                if isWord(before) != isWord(after) {
                    out.append("\\_")
                } else {
                    out.append(ch)
                }
            case "*":
                // Only bare asterisks between spaces are safe to leave alone.
                if isSpace(before) && isSpace(after) {
                    out.append(ch)
                } else {
                    out.append("\\*")
                }
            case "|" where inTableCell:
                out.append("\\|")
            default:
                out.append(ch)
            }
        }
        return out
    }

    /// Escapes a leading character that would otherwise start a block: a
    /// heading, list item, quote, or fence.  Applied once per emitted line,
    /// after inline escaping.
    static func escapeLeadingBlockMarker(_ line: String) -> String {
        guard let first = line.first else { return line }

        if first == "#" || first == ">" || first == "-" || first == "+" || first == "=" {
            return "\\" + line
        }

        // "1." or "1)" at the start of a line begins an ordered list.
        let chars = Array(line)
        var i = 0
        while i < chars.count, chars[i].isNumber { i += 1 }
        if i > 0, i < chars.count, chars[i] == "." || chars[i] == ")" {
            return String(chars[0..<i]) + "\\" + String(chars[i...])
        }

        return line
    }

    private static func isWord(_ ch: Character?) -> Bool {
        guard let ch else { return false }
        return ch.isLetter || ch.isNumber
    }

    private static func isSpace(_ ch: Character?) -> Bool {
        guard let ch else { return false }
        return ch == " " || ch == "\t"
    }
}
