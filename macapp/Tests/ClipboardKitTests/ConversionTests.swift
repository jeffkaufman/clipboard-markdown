import XCTest
@testable import ClipboardKit

final class ConversionTests: XCTestCase {

    // MARK: - Golden files

    /// The same examples/example.html the pandoc-based tests use.
    private func repositoryFile(_ path: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // ClipboardKitTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // macapp
            .deletingLastPathComponent()  // repository root
        return try String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
    }

    private func fixture(_ name: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent(name)
        return try String(contentsOf: url, encoding: .utf8)
    }

    func testMarkdownifyExample() throws {
        let html = try repositoryFile("examples/example.html")
        XCTAssertEqual(try HTMLToMarkdown.convert(html), try fixture("example.md"))
    }

    func testNormalizeExample() throws {
        let html = try repositoryFile("examples/example.html")
        let expected = try fixture("example_normalized.html")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(try ClipboardConversions.normalize(html: html), expected)
    }

    // MARK: - HTML to Markdown

    func testInlineFormatting() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<p><b>bold</b> and <i>italic</i></p>"),
            "**bold** and *italic*\n"
        )
    }

    func testSpacesMoveOutsideEmphasisMarkers() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<p>a<strong> b </strong>c</p>"),
            "a **b** c\n"
        )
    }

    func testLink() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<p>see <a href=\"https://x.test/a\">here</a></p>"),
            "see [here](https://x.test/a)\n"
        )
    }

    func testLinkWithSpaceInURLIsBracketed() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<a href=\"https://x.test/a b\">here</a>"),
            "[here](<https://x.test/a b>)\n"
        )
    }

    func testHeadings() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<h1>One</h1><h3>Three</h3>"),
            "# One\n\n### Three\n"
        )
    }

    func testNestedLists() throws {
        let html = "<ul><li>a<ul><li>b</li></ul></li><li>c</li></ul>"
        XCTAssertEqual(try HTMLToMarkdown.convert(html), "- a\n  - b\n- c\n")
    }

    func testOrderedListRespectsStart() throws {
        let html = "<ol start=\"3\"><li>c</li><li>d</li></ol>"
        XCTAssertEqual(try HTMLToMarkdown.convert(html), "3. c\n4. d\n")
    }

    func testBlockquote() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<blockquote><p>quoted</p></blockquote>"),
            "> quoted\n"
        )
    }

    func testCodeBlockKeepsWhitespaceAndLanguage() throws {
        let html = "<pre><code class=\"language-swift\">let x = 1\n  let y = 2\n</code></pre>"
        XCTAssertEqual(
            try HTMLToMarkdown.convert(html),
            "```swift\nlet x = 1\n  let y = 2\n```\n"
        )
    }

    func testInlineCodeIsNotEscaped() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<p><code>a_b*c</code></p>"),
            "`a_b*c`\n"
        )
    }

    func testHardBreak() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<p>one<br>two</p>"),
            "one  \ntwo\n"
        )
    }

    func testSuperscriptAndSubscript() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<p>H<sub>2</sub>O and x<sup>2</sup></p>"),
            "H₂O and x²\n"
        )
    }

    func testUnmappableSuperscriptFallsBackToText() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<p>x<sup>qq</sup></p>"),
            "xqq\n"
        )
    }

    func testStyleAndScriptAreDropped() throws {
        let html = "<style>p { color: red }</style><p>kept</p><script>alert(1)</script>"
        XCTAssertEqual(try HTMLToMarkdown.convert(html), "kept\n")
    }

    func testWhitespaceIsCollapsed() throws {
        XCTAssertEqual(
            try HTMLToMarkdown.convert("<p>a\n   b\t\tc</p>"),
            "a b c\n"
        )
    }

    func testTableWithAlignment() throws {
        let html = """
        <table><tr><th>a</th><th align="right">b</th></tr>
        <tr><td>1</td><td>2</td></tr></table>
        """
        XCTAssertEqual(
            try HTMLToMarkdown.convert(html),
            """
            | a   | b   |
            |-----|----:|
            | 1   | 2   |

            """
        )
    }

    func testTableWithoutHeaderPromotesFirstRow() throws {
        let html = "<table><tr><td>a</td><td>b</td></tr><tr><td>1</td><td>2</td></tr></table>"
        XCTAssertEqual(
            try HTMLToMarkdown.convert(html),
            "| a   | b   |\n|-----|-----|\n| 1   | 2   |\n"
        )
    }

    func testPipeInsideTableCellIsEscaped() throws {
        let html = "<table><tr><th>a</th></tr><tr><td>x | y</td></tr></table>"
        XCTAssertTrue(try HTMLToMarkdown.convert(html).contains("x \\| y"))
    }

    func testNestedTableIsNotEmittedTwice() throws {
        let html = "<table><tr><td><table><tr><td>inner</td></tr></table></td></tr></table>"
        let markdown = try HTMLToMarkdown.convert(html)
        XCTAssertEqual(markdown.components(separatedBy: "inner").count - 1, 1)
    }

    func testTextThatLooksLikeABlockMarkerIsEscaped() throws {
        XCTAssertEqual(try HTMLToMarkdown.convert("<p># not a heading</p>"),
                       "\\# not a heading\n")
    }

    func testEmptyDocument() throws {
        XCTAssertEqual(try HTMLToMarkdown.convert(""), "")
        XCTAssertEqual(try HTMLToMarkdown.convert("<p></p>"), "")
    }

    // MARK: - Markdown to HTML

    func testMarkdownToHTML() {
        XCTAssertEqual(
            MarkdownToHTML.convert("# Title\n\nSome **bold** text."),
            "<h1>Title</h1>\n<p>Some <strong>bold</strong> text.</p>"
        )
    }

    func testMarkdownToHTMLTable() {
        let html = MarkdownToHTML.convert("| a | b |\n|---|---|\n| 1 | 2 |")
        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("<th>a</th>"))
    }

    func testMarkdownToHTMLTightList() {
        XCTAssertEqual(
            MarkdownToHTML.convert("- a\n- b"),
            "<ul>\n<li>a\n</li>\n<li>b\n</li>\n</ul>"
        )
    }

    func testMarkdownToHTMLKeepsParagraphsInLooseList() {
        let html = MarkdownToHTML.convert("- a\n\n  still a\n\n- b")
        XCTAssertTrue(html.contains("<p>a</p>"))
    }

    // MARK: - Round trips

    func testNormalizeStripsPresentationalMarkup() throws {
        let html = """
        <p style="color: red"><span class="fancy" style="font-size: 40px">Hello</span>
        <b>world</b></p>
        """
        XCTAssertEqual(
            try ClipboardConversions.normalize(html: html),
            "<p>Hello <strong>world</strong></p>"
        )
    }

    func testNormalizeKeepsWhatMarkdownCannotExpress() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(
                html: "<p><u>under</u> H<sub>2</sub>O x<sup>2</sup></p>"),
            "<p><u>under</u> H<sub>2</sub>O x<sup>2</sup></p>"
        )
    }

    func testNormalizeKeepsMergedTableCells() throws {
        let html = "<table><tr><th colspan=\"2\">Wide</th></tr>"
            + "<tr><td>a</td><td>b</td></tr></table>"
        XCTAssertTrue(try ClipboardConversions.normalize(html: html)
            .contains("<th colspan=\"2\">Wide</th>"))
    }

    func testNormalizeKeepsImageAltText() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(
                html: "<img src=\"https://x.test/a.png\" alt=\"pic\" width=\"90\">"),
            "<p><img src=\"https://x.test/a.png\" alt=\"pic\" /></p>"
        )
    }

    func testNormalizeKeepsDescriptionLists() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(html: "<dl><dt>Term</dt><dd>Def</dd></dl>"),
            "<dl><dt>Term</dt><dd>Def</dd></dl>"
        )
    }

    func testNormalizeModernizesLegacyTags() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(
                html: "<p><b>b</b> <i>i</i> <strike>s</strike></p>"),
            "<p><strong>b</strong> <em>i</em> <del>s</del></p>"
        )
    }

    func testNormalizeWrapsLooseTextInParagraphs() throws {
        // A <div> of styled spans is what most editors put on the clipboard.
        // Without a block wrapper the text would merge into the paragraph you
        // paste it into.
        XCTAssertEqual(
            try ClipboardConversions.normalize(
                html: "<div><span style=\"color:red\">a</span><span> b</span></div>"),
            "<p>a b</p>"
        )
    }

    func testNormalizeWrapsLooseTextInsideBlockquotes() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(html: "<blockquote>loose<p>para</p></blockquote>"),
            "<blockquote><p>loose</p><p>para</p></blockquote>"
        )
    }

    func testNormalizeDropsUnsafeLinksButKeepsRelativeOnes() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(
                html: "<p><a href=\"javascript:alert(1)\">click</a> <a href=\"/rel\">rel</a></p>"),
            "<p>click <a href=\"/rel\">rel</a></p>"
        )
    }

    func testNormalizeDropsUnsafeLinksHidingBehindWhitespace() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(
                html: "<p><a href=\"java\tscript:alert(1)\">click</a></p>"),
            "<p>click</p>"
        )
    }

    func testNormalizeKeepsMailtoAndTelLinks() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(
                html: "<p><a href=\"mailto:a@b.test\">mail</a> <a href=\"tel:+15551234\">call</a></p>"),
            "<p><a href=\"mailto:a@b.test\">mail</a> <a href=\"tel:+15551234\">call</a></p>"
        )
    }

    func testNormalizeDropsUncommonSchemes() throws {
        for url in ["file:///Users/x/doc.html", "cid:part1@mail",
                    "blob:https://x.test/uuid", "obsidian://open?vault=x",
                    "webcal://x.test/c.ics", "vbscript:msgbox(1)"] {
            XCTAssertEqual(
                try ClipboardConversions.normalize(html: "<p><a href=\"\(url)\">x</a></p>"),
                "<p>x</p>",
                "expected \(url) to lose its link"
            )
        }
    }

    func testNormalizeKeepsFragmentAndProtocolRelativeLinks() throws {
        for url in ["#anchor", "/absolute-path", "relative.html", "//cdn.x.test/a"] {
            XCTAssertEqual(
                try ClipboardConversions.normalize(html: "<p><a href=\"\(url)\">x</a></p>"),
                "<p><a href=\"\(url)\">x</a></p>",
                "expected \(url) to stay linked"
            )
        }
    }

    func testNormalizeTreatsALateColonAsPathNotScheme() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(html: "<p><a href=\"page.html?a=b:c\">x</a></p>"),
            "<p><a href=\"page.html?a=b:c\">x</a></p>"
        )
    }

    func testNormalizeDropsDataURIImages() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(
                html: "<p><img src=\"data:image/gif;base64,R0lGODlhAQABAAAAACw=\"></p>"),
            ""
        )
    }

    func testNormalizeKeepsBlocksThatStillHoldContent() throws {
        // A paragraph holding only a <br> or an image is not empty.
        XCTAssertEqual(try ClipboardConversions.normalize(html: "<p><br></p>"), "<p><br /></p>")
        // An empty cell still holds its column open.
        XCTAssertEqual(
            try ClipboardConversions.normalize(
                html: "<table><tr><td>a</td><td></td></tr></table>"),
            "<table><tbody><tr><td>a</td><td></td></tr></tbody></table>"
        )
    }

    func testNormalizeDropsEmptyParagraphs() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(html: "<p>a</p><p>   </p><p></p><p>b</p>"),
            "<p>a</p>\n<p>b</p>"
        )
    }

    func testNormalizeKeepsHTTPImages() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(html: "<img src=\"https://x.test/a.png\" alt=\"p\">"),
            "<p><img src=\"https://x.test/a.png\" alt=\"p\" /></p>"
        )
    }

    func testNormalizeCollapsesSourceIndentation() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(html: "<p>\n    a\n    b\n</p>"),
            "<p>a b</p>"
        )
    }

    func testNormalizePreservesPreformattedWhitespace() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(html: "<pre>a\n  b</pre>"),
            "<pre>a\n  b</pre>"
        )
    }

    func testNormalizeDropsScriptsAndStyles() throws {
        XCTAssertEqual(
            try ClipboardConversions.normalize(
                html: "<style>p{color:red}</style><p>kept</p><script>alert(1)</script>"),
            "<p>kept</p>"
        )
    }

    func testNormalizeIsStable() throws {
        let html = try repositoryFile("examples/example.html")
        let once = try ClipboardConversions.normalize(html: html)
        XCTAssertEqual(try ClipboardConversions.normalize(html: once), once)
    }
}
