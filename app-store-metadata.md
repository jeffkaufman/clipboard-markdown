# App Store Connect metadata

The text to paste into App Store Connect, kept here so it is versioned with the
app instead of being retyped from memory at each release.  Field length limits
are noted where App Store Connect enforces one.

## App information

- **Name** (30): Clipboard Normalizer
- **Subtitle** (30): Clean up formatting on paste
- **Bundle ID**: com.jefftk.ClipboardNormalizer
- **Primary category**: Utilities
- **Secondary category**: Productivity
- **Copyright**: 2026 Jeff Kaufman
- **Support URL**: https://www.jefftk.com/p/clipboard-normalization
- **Marketing URL**: https://github.com/jeffkaufman/clipboard-markdown
- **Privacy policy URL**: https://www.jefftk.com/clipboard-normalizer-privacy-policy

## Promotional text (170)

Copy from anywhere, drop the fonts and colors, and paste text that matches your doc.

## Description (4000)

Clipboard Normalizer is a menu bar utility for cleaning up what's on your
clipboard before you paste.

* Normalize Clipboard: remove extra styling from rich text / HTML.  For pasting
text into docs while matching the existing styling.  An option in between
"Cmd-V" which pastes everything and "Cmd+Shift+V" which pastes without
formatting.

* Convert Clipboard to Markdown: rich text / HTML in, Markdown out. For pasting
into anything that uses Markdown, and for handing formatted text to an LLM.

* Convert Clipboard to HTML: Markdown in, rich text / HTML out. The opposite.

No window or anything to configure.  The app sits in the menu bar: copy text, click
the app icon, pick the conversion, and paste the converted text.

Clipboard Normalizer does all of its work on your Mac. It has no network access
at all, collects nothing, and reads your clipboard only when you ask it to run a
conversion.

Open source under the MIT license:
https://github.com/jeffkaufman/clipboard-markdown

## Keywords (100, comma separated, no spaces after commas)

markdown,html,rich,plain,text,convert,copy,strip,remove,font,color,style,menubar,llm,md

## App Review notes

This is a menu bar app. It has no Dock icon and no window, so after it launches
the only sign of it is the clipboard icon near the right-hand end of the macOS
menu bar. Click that icon to see the menu.

To test it:

1. Copy some formatted text from a web page, for example a paragraph with a
   bold word and a link in it.
2. Click the clipboard icon in the menu bar and choose "Convert Clipboard to
   Markdown".
3. Paste into TextEdit in plain text mode (Format > Make Plain Text). The text
   arrives as Markdown, with ** around the bold word and the link written as
   [text](url).

"Normalize Clipboard" is best seen by pasting into a document that already has
its own styling: the pasted text takes on the destination's font and size
instead of carrying the source's.

No account or login is needed and the app has no network access.

## App privacy

Data collection: **No data collected.** The app has no network entitlement, no
analytics, and no server component.

## Screenshots

Current shot: `~/Desktop/clipboard-normalizer-screenshot.png`, 1280x800.

At least one is required, sized 1280x800, 1440x900, 2560x1600, or 2880x1800. The
useful shot is the menu bar with the app's own menu open, so the reviewer can
see where the app lives. Quit the dev build first: otherwise its name shows up
in the Quit item and its icon shows up in the menu bar.
