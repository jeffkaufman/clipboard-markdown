import XCTest
@testable import ClipboardKit

/// These mirror the escaping cases in the repo's test_clipboard.py, which
/// described the behavior of pandoc plus bin/unescape-markdown.  Here the same
/// results come out of the escaper directly.
final class EscapingTests: XCTestCase {

    private func escape(_ text: String) -> String {
        MarkdownEscaping.escape(text)
    }

    func testDollarIsNeverEscaped() {
        XCTAssertEqual(escape("$foo"), "$foo")
        XCTAssertEqual(escape("$x$"), "$x$")
    }

    func testPipeIsNotEscapedOutsideTables() {
        XCTAssertEqual(escape("| bar"), "| bar")
    }

    func testPipeIsEscapedInsideTableCells() {
        XCTAssertEqual(MarkdownEscaping.escape("a | b", inTableCell: true), "a \\| b")
    }

    func testBracketsAreNotEscaped() {
        XCTAssertEqual(escape("[1]"), "[1]")
    }

    func testUnderscoreInsideWord() {
        XCTAssertEqual(escape("file_name"), "file_name")
        XCTAssertEqual(escape("foo_bar_baz"), "foo_bar_baz")
    }

    func testUnderscoreAtWordBoundaryStaysEscaped() {
        XCTAssertEqual(escape("_italic_"), "\\_italic\\_")
        XCTAssertEqual(escape("foo _bar"), "foo \\_bar")
        XCTAssertEqual(escape("foo_ bar"), "foo\\_ bar")
    }

    func testUnderscoreSurroundedBySpaces() {
        XCTAssertEqual(escape("foo _ bar"), "foo _ bar")
    }

    func testAsteriskSurroundedBySpaces() {
        XCTAssertEqual(escape("3 * 4"), "3 * 4")
    }

    func testAsteriskOtherwiseStaysEscaped() {
        XCTAssertEqual(escape("*bold*"), "\\*bold\\*")
        XCTAssertEqual(escape("foo *bar* baz"), "foo \\*bar\\* baz")
        XCTAssertEqual(escape("3 *4"), "3 \\*4")
        XCTAssertEqual(escape("3* 4"), "3\\* 4")
        XCTAssertEqual(escape("* foo"), "\\* foo")
        XCTAssertEqual(escape("foo *"), "foo \\*")
    }

    func testCombinedEscapes() {
        XCTAssertEqual(
            escape("$foo | bar [1] file_name 3 * 4"),
            "$foo | bar [1] file_name 3 * 4"
        )
    }

    func testBackslashAndBacktick() {
        XCTAssertEqual(escape("a \\ b"), "a \\\\ b")
        XCTAssertEqual(escape("a ` b"), "a \\` b")
    }

    func testLeadingBlockMarkers() {
        XCTAssertEqual(MarkdownEscaping.escapeLeadingBlockMarker("# not a heading"),
                       "\\# not a heading")
        XCTAssertEqual(MarkdownEscaping.escapeLeadingBlockMarker("> not a quote"),
                       "\\> not a quote")
        XCTAssertEqual(MarkdownEscaping.escapeLeadingBlockMarker("1. not a list"),
                       "1\\. not a list")
        XCTAssertEqual(MarkdownEscaping.escapeLeadingBlockMarker("ordinary text"),
                       "ordinary text")
    }
}
