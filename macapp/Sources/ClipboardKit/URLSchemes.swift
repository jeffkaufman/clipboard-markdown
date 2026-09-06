import Foundation

/// URL schemes worth carrying out of the clipboard, shared by every conversion
/// so they cannot disagree about what is safe.
///
/// Anything not listed — `javascript:` and `vbscript:`, but also `file:`,
/// `cid:`, `blob:`, `data:`, and application schemes like `obsidian://` — loses
/// its link.  A URL with no scheme at all is relative (`/path`, `page.html`,
/// `#anchor`, `//host/path`) and is kept: it cannot name a protocol, so it
/// cannot name a dangerous one.
enum URLSchemes {
    static let links: Set<String> = ["http", "https", "ftp", "mailto", "tel"]
    static let images: Set<String> = ["http", "https", "ftp"]

    static func isAllowed(_ url: String, schemes: Set<String>) -> Bool {
        guard let scheme = scheme(of: url) else { return true }
        return schemes.contains(scheme)
    }

    /// The scheme of an absolute URL, or nil if the URL is relative.
    ///
    /// Whitespace and control characters are skipped, because browsers skip
    /// them too, which makes "java&#9;script:" name the javascript scheme.
    /// That errs strict: a browser treats "java script:" as a relative URL
    /// while we read it as javascript and drop it, which is the safe side to be
    /// wrong on.  A colon arriving after a "/", "?", or "#" is part of the path
    /// rather than a scheme, so "page.html?a=b:c" is relative.
    static func scheme(of url: String) -> String? {
        var scheme = ""
        for character in url.lowercased().unicodeScalars {
            guard character.value > 0x20,
                  !CharacterSet.whitespacesAndNewlines.contains(character)
            else { continue }

            if character == ":" { return scheme.isEmpty ? nil : scheme }

            // A scheme is a letter, then letters, digits, "+", "-", or ".".
            let isLetter = CharacterSet.letters.contains(character)
            let isValid = scheme.isEmpty
                ? isLetter
                : isLetter
                    || CharacterSet.decimalDigits.contains(character)
                    || "+-.".unicodeScalars.contains(character)
            guard isValid else { return nil }
            scheme.unicodeScalars.append(character)
        }
        return nil
    }
}
