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

## App Review notes (4000)

Pasted into the Notes field and also sent as the reply to App Review, which
asked for these six items (Guideline 2.1, limited review history).  The screen
recording goes in the Attachment field and on the reply.

1. SCREEN RECORDING

Attached. Recorded on a Mac running macOS 26.6.2, starting from launching
the app and showing the typical flow. The app has no accounts, no user-generated
content, and no paid content or features.

2. PURPOSE AND AUDIENCE

When you copy text from a web page or another document, the clipboard carries
the source's fonts, sizes, colors, and backgrounds. Pasting with Cmd-V brings
all of that along, so the pasted text clashes with the document it lands in.
Cmd-Shift-V goes too far the other way and drops everything, including bold,
italics, links, headings, and lists.

Clipboard Normalizer fills the gap. It is for anyone who writes in documents,
email, or chat and moves text between them, and for people who work in Markdown
or hand text to LLMs. From its menu bar icon it offers three conversions of
whatever is on the clipboard:

- Normalize Clipboard: keeps structure (bold, italics, links, headings, lists)
  and removes presentation (fonts, sizes, colors, backgrounds), so pasted text
  takes on the destination document's style.
- Convert Clipboard to Markdown: rich text / HTML in, Markdown out.
- Convert Clipboard to HTML: Markdown in, rich text out.

3. SETUP AND INSTRUCTIONS

No setup, login, or credentials are needed. This is a menu bar app with no Dock
icon and no window: after launch, the only sign of it is the clipboard icon with
an "N" near the right-hand end of the menu bar. Click it to see the menu.

A sample page for testing is at https://www.jefftk.com/formatting-demo

- Normalize: open the sample page, select all, and copy. Click the menu bar icon
  and choose "Normalize Clipboard". Paste into a styled document (for example a
  Pages or Google Docs document with a non-default font). The text keeps its
  bold, italics, links, and headings but takes on the document's font, size,
  and color.
- Markdown: copy from the sample page again, choose "Convert Clipboard to
  Markdown", and paste into TextEdit in plain text mode (Format > Make Plain
  Text). The text arrives as Markdown, e.g. **bold** and [text](url).
- HTML: copy some Markdown text, choose "Convert Clipboard to HTML", and paste
  into a rich text editor such as Pages or Mail. It arrives formatted.

The menu also has "Launch at Login" and "Quit Clipboard Normalizer".

4. EXTERNAL SERVICES

None. All conversions run locally on the Mac. The app has no network
entitlement and makes no network connections, and it uses no external services:
no analytics, authentication, payments, data providers, or AI services. The only
third-party code is SwiftSoup, an open source (MIT) HTML parsing library compiled
into the app. It reads the clipboard only when the user chooses a conversion.

5. REGIONAL DIFFERENCES

None. The app works the same in all regions.

6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL

Not applicable. The app is not in a regulated industry and includes no
protected third-party material. It is my own open source code (MIT license):
https://github.com/jeffkaufman/clipboard-markdown

## App privacy

Data collection: **No data collected.** The app has no network entitlement, no
analytics, and no server component.

## Screenshots

Current shot: `~/Desktop/clipboard-normalizer-screenshot.png`, 1280x800.

At least one is required, sized 1280x800, 1440x900, 2560x1600, or 2880x1800. The
useful shot is the menu bar with the app's own menu open, so the reviewer can
see where the app lives. Quit the dev build first: otherwise its name shows up
in the Quit item and its icon shows up in the menu bar.
