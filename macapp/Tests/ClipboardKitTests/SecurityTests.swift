import XCTest
import SwiftSoup
@testable import ClipboardKit

/// Normalizing is a sanitizing step: the HTML comes from whatever page the user
/// copied from, and the result gets pasted into a document, an email, or a CMS.
/// These check that known injection and mutation-XSS shapes come out inert.
final class SecurityTests: XCTestCase {

    private static let payloads: [(String, String)] = [
        ("script", "<script>alert(1)</script>"),
        ("img onerror", "<img src=x onerror=alert(1)>"),
        ("mixed-case scheme", "<a href=\"  jAvAsCrIpT:alert(1)\">x</a>"),
        ("entity-encoded scheme", "<a href=\"java&#115;cript:alert(1)\">x</a>"),
        ("leading-entity scheme", "<a href=\"&#106;avascript:alert(1)\">x</a>"),
        ("newline in scheme", "<a href=\"java\nscript:alert(1)\">x</a>"),
        ("NUL in scheme", "<a href=\"java\u{0000}script:alert(1)\">x</a>"),
        ("svg script", "<svg><script>alert(1)</script></svg>"),
        ("mXSS via math", "<math><mtext><table><mglyph><style><!--</style>"
                        + "<img src=x onerror=alert(1)>"),
        ("mXSS via noscript", "<noscript><p title=\"</noscript>"
                            + "<img src=x onerror=alert(1)>\">"),
        ("comment mXSS", "<!--><script>alert(1)</script>-->"),
        ("attribute breakout", "<a href=\"http://x\" title='\"><script>alert(1)</script>'>x</a>"),
        ("alt breakout", "<img src=\"https://x/a.png\" alt='\"><script>alert(1)</script>'>"),
        ("quoted handler in href", "<a href=\"http://x&quot; onclick=&quot;alert(1)\">x</a>"),
        ("style import", "<style>@import url(evil)</style>"),
        ("iframe", "<iframe src=javascript:alert(1)></iframe>"),
        ("iframe srcdoc", "<iframe srcdoc=\"<script>alert(1)</script>\"></iframe>"),
        ("form action", "<form><button formaction=javascript:alert(1)>go</button></form>"),
        ("template", "<template><script>alert(1)</script></template>"),
        ("xmp", "<xmp><script>alert(1)</script></xmp>"),
        ("plaintext", "<plaintext><script>alert(1)</script>"),
        ("textarea escape", "<textarea></textarea><script>alert(1)</script>"),
        ("select noembed", "<select><noembed></select><script>alert(1)</script>"),
        ("handler on allowed tag", "<a href=\"/x\" onclick=\"alert(1)\">x</a>"),
        ("base tag", "<base href=\"javascript:\"><a href=\"alert(1)\">x</a>"),
        ("object", "<object data=\"javascript:alert(1)\"></object>"),
        ("embed", "<embed src=\"javascript:alert(1)\">"),
    ]

    /// The output is re-parsed, because that is what the destination app does.
    /// A sanitizer that emits markup which *re-parses* into something dangerous
    /// is the classic mutation-XSS failure, and only re-parsing catches it.
    func testNormalizedOutputIsInertWhenReparsed() throws {
        for (name, payload) in Self.payloads {
            let output = try ClipboardConversions.normalize(html: payload)
            let reparsed = try SwiftSoup.parseBodyFragment(output)

            let executable = try reparsed
                .select("script, iframe, object, embed, svg, math, style, link, base, form")
                .size()
            XCTAssertEqual(executable, 0, "\(name): executable element survived in \(output)")

            for element in try reparsed.select("*") {
                for attribute in element.getAttributes()?.asList() ?? [] {
                    XCTAssertFalse(
                        attribute.getKey().lowercased().hasPrefix("on"),
                        "\(name): event handler survived in \(output)"
                    )
                }
            }

            for node in try reparsed.select("a[href], img[src]") {
                for key in ["href", "src"] where node.hasAttr(key) {
                    let value = try node.attr(key).lowercased()
                        .components(separatedBy: .whitespacesAndNewlines).joined()
                    for scheme in ["javascript:", "vbscript:", "data:"] {
                        XCTAssertFalse(
                            value.hasPrefix(scheme),
                            "\(name): \(scheme) survived in \(output)"
                        )
                    }
                }
            }
        }
    }

    /// Normalizing an already-normalized document must be a no-op.  Drift here
    /// would mean the serializer and the parser disagree, which is the same
    /// disagreement mutation-XSS exploits.
    func testNormalizingIsAFixpointForHostilePayloads() throws {
        for (name, payload) in Self.payloads {
            let once = try ClipboardConversions.normalize(html: payload)
            let twice = try ClipboardConversions.normalize(html: once)
            XCTAssertEqual(twice, once, "\(name): not stable")
        }
    }

    /// Markdown lets raw HTML through untouched, and swift-markdown's formatter
    /// does not filter it, so "Convert to HTML" has to sanitize its own output.
    func testHTMLifiedMarkdownIsSanitized() throws {
        let cases = [
            "<script>alert(1)</script>",
            "[x](javascript:alert(1))",
            "[x](<javascript:alert(1)>)",
            "![x](javascript:alert(1))",
            "<img src=x onerror=alert(1)>",
            "<div onclick=\"alert(1)\">x</div>",
            "<iframe src=\"https://evil.test\"></iframe>",
            "<a href=\"vbscript:msgbox(1)\">x</a>",
        ]
        for markdown in cases {
            let output = try ClipboardConversions.htmlify(markdown: markdown)
            let reparsed = try SwiftSoup.parseBodyFragment(output)

            XCTAssertEqual(
                try reparsed.select("script, iframe, object, embed, style").size(), 0,
                "\(markdown): executable element survived in \(output)"
            )
            for element in try reparsed.select("*") {
                for attribute in element.getAttributes()?.asList() ?? [] {
                    XCTAssertFalse(attribute.getKey().lowercased().hasPrefix("on"),
                                   "\(markdown): handler survived in \(output)")
                }
            }
            XCTAssertFalse(output.lowercased().contains("javascript:"),
                           "\(markdown): javascript: survived in \(output)")
            XCTAssertFalse(output.lowercased().contains("vbscript:"),
                           "\(markdown): vbscript: survived in \(output)")
        }
    }

    func testHTMLifyStillProducesOrdinaryMarkup() throws {
        XCTAssertEqual(
            try ClipboardConversions.htmlify(markdown: "# Title\n\nSome **bold** text."),
            "<h1>Title</h1>\n<p>Some <strong>bold</strong> text.</p>"
        )
        XCTAssertEqual(
            try ClipboardConversions.htmlify(markdown: "- a\n- b"),
            "<ul><li>a</li><li>b</li></ul>"
        )
        XCTAssertEqual(
            try ClipboardConversions.htmlify(markdown: "[x](https://ok.test)"),
            "<p><a href=\"https://ok.test\">x</a></p>"
        )
    }

    /// Markdownifying used to decode an obfuscated javascript: URL into a clean
    /// working one, which "Convert to HTML" would then have made live.
    func testMarkdownifyDropsUnsupportedSchemes() throws {
        for html in ["<a href=\"javascript:alert(1)\">x</a>",
                     "<a href=\"java&#115;cript:alert(1)\">x</a>",
                     "<a href=\"  jAvAsCrIpT:alert(1)\">x</a>",
                     "<a href=\"vbscript:msgbox(1)\">x</a>",
                     "<a href=\"file:///etc/passwd\">x</a>"] {
            XCTAssertEqual(try ClipboardConversions.markdownify(html: html), "x\n",
                           "expected \(html) to lose its link")
        }
        XCTAssertEqual(
            try ClipboardConversions.markdownify(
                html: "<img src=\"data:image/gif;base64,R0lGODlhAQABAAAAACw=\" alt=\"x\">"),
            ""
        )
    }

    func testMarkdownifyKeepsSupportedSchemes() throws {
        XCTAssertEqual(
            try ClipboardConversions.markdownify(html: "<a href=\"mailto:a@b.test\">mail</a>"),
            "[mail](mailto:a@b.test)\n"
        )
        XCTAssertEqual(
            try ClipboardConversions.markdownify(html: "<a href=\"#anchor\">x</a>"),
            "[x](#anchor)\n"
        )
        XCTAssertEqual(
            try ClipboardConversions.markdownify(html: "<a href=\"https://ok.test\">x</a>"),
            "[x](https://ok.test)\n"
        )
    }

    func testAttributeValuesAreEscapedRatherThanDropped() throws {
        // The quote is escaped, so the payload stays inside the attribute value
        // instead of starting a new attribute or tag.
        let output = try ClipboardConversions.normalize(
            html: "<a href=\"http://x\" title='\"><script>alert(1)</script>'>x</a>")
        XCTAssertTrue(output.contains("&quot;"), output)
        let reparsed = try SwiftSoup.parseBodyFragment(output)
        let link = try reparsed.select("a").first()
        XCTAssertEqual(try link?.attr("title"), "\"><script>alert(1)</script>")
    }
}
