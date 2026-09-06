# Clipboard Markdown

When you copy text it often carries extra formatting (colors, fonts,
sizes). The Normalize Clipboard utility fixes this by limiting it to basic
formatting (bold, italic, links) so it matches your destination document.

Many LLMs understand rich text when presented as Markdown, but not directly.
The Markdownify Clipboard utility converts rich text to Markdown, ready to
paste.

Both work by modifying your clipboard in place.  For example, I could copy some
colorful text, run "Normalize Clipboard", and paste into an existing document
where it would match the style of what I was already working on.

See https://www.jefftk.com/p/clipboard-normalization

## Clipboard Markdown (menu bar app)

`macapp/` holds a single native menu bar app that does all three conversions:

- **Normalize Clipboard** — rich text in, simplified rich text out
- **Convert Clipboard to Markdown** — rich text in, Markdown out
- **Convert Clipboard to HTML** — Markdown in, rich text out

It does the conversion itself in Swift, using
[SwiftSoup](https://github.com/scinfu/SwiftSoup) to parse HTML and
[swift-markdown](https://github.com/apple/swift-markdown) to render it, so it
needs no Pandoc and no other setup. It runs in the App Sandbox and is the
version intended for the Mac App Store. It also offers a "Launch at Login"
toggle, which works for the app on its own rather than needing a trip through
System Settings.

To build and install it:

```bash
$ make app-install
```

The apps described below are the original Pandoc-based ones, kept for the
command line tools and for people already using them.

## Prerequisite: Install Pandoc

If you use Homebrew this is just:

```bash
$ brew install pandoc
```

Otherwise:

1. Go to https://pandoc.org/installing.html

2. Click "Download the latest installer"

3. Download the file named `pandoc-...-arm64-macOS.pkg` (for Apple Silicon
   Macs) or `pandoc-...-x86_64-macOS.pkg` (for Intel Macs)

4. Open the downloaded `.pkg` file and follow the installation wizard

## Pre-built Apps

The easiest way to use these tools is to download the pre-built Mac apps.  To
install:

1. **Download** one or both apps:

- [Normalize Clipboard.app](https://www.jefftk.com/normalize-clipboard-app.zip)
- [Markdownify Clipboard.app](https://www.jefftk.com/markdownify-clipboard-app.zip)

   **Note:** If using Chrome, you may see "Suspicious Download Blocked":
   - Click the download icon (^) in Chrome's toolbar
   - Find the blocked download
   - Click **Show all** if needed
   - Click **Keep** (or **Keep dangerous file**)
   - Confirm by clicking **Keep** again if prompted

2. **Extract** the `.zip` file by double-clicking it

3. **Move to Applications folder:**
   - Drag the `.app` file to your `/Applications` folder

4. **Open the app for the first time:**
   - Double-click the app in your Applications folder
   - macOS will likely show a warning that the app "cannot be opened because it
     is from an unidentified developer"
   - Click "OK" to dismiss the warning

5. **Approve the app to run:**
   - Open **System Settings**
   - Go to **Privacy & Security**
   - Scroll down to find a message about the app being blocked
   - Click **Open Anyway**
   - Click **Open** in the confirmation dialog

6. **Add to startup (optional but recommended):**
   - Open **System Settings** > **General** > **Login Items**
   - Click the **+** button
   - Select the app from your Applications folder
     - For reasons I haven't figured out yet, you can only set one of the two
       to run on startup.
   - The app will now run automatically when you log in

The apps will appear as icons in your menu bar. Click them to run the clipboard
conversion.

## Building from Source

### Requirements

- macOS
- [Pandoc](https://pandoc.org/)
- Xcode Command Line Tools (for building the Swift binary)

### Installation

1. Clone or download this repository:
   ```bash
   $ git clone https://github.com/jeffkaufman/clipboard-markdown.git
   $ cd clipboard-markdown
   ```

3. Build the html-clipboard binary:
   ```bash
   $ make
   ```
   This compiles the Swift source code into the `bin/html-clipboard` executable.
   Without this step, the scripts will not work.

## Command Line Tool Usage

### markdownify-clipboard

Converts the clipboard from HTML to plain Markdown text.

```bash
$ markdownify-clipboard
```

**Example:**
1. Copy formatted text from a web page
2. Run `markdownify-clipboard`
3. Paste.  You'll get plain Markdown text

### markdown-to-clipboard

Reads Markdown from stdin, converts it to HTML, and puts it on the clipboard as
rich text (and plain text), ready to paste.

```bash
$ markdown-to-clipboard
```

**Example:**
```bash
$ echo "# Title" | markdown-to-clipboard      # Put formatted HTML on clipboard
```

### normalize-clipboard

Normalizes HTML formatting by converting clipboard HTML to Markdown and back to
HTML, removing unnecessary formatting.

```bash
$ normalize-clipboard
```

**Example:**
1. Copy formatted HTML from a document
2. Run `normalize-clipboard`
3. Paste.  The HTML will be cleaner and simplified

### html-clipboard

Low-level utility for getting and setting HTML on the clipboard.

```bash
$ html-clipboard get        # Print HTML from clipboard to stdout
$ html-clipboard set        # Read HTML from stdin and put on clipboard
```

**Example:**
```bash
$ html-clipboard get > saved.html                # Get HTML from clipboard
$ echo "<h1>Title</h1>" | html-clipboard set     # Put HTML on clipboard
```

## Adding to PATH

To run these scripts from anywhere, add the bin directory to your PATH. For
example, add to your `~/.bashrc` or `~/.zshrc`:

```bash
$ export PATH="$PATH:/path/to/clipboard-markdown/bin"
```

## Testing

The menu bar app's conversions have their own test suite, which does not touch
the system clipboard:

```bash
$ make app-test
```

The Pandoc scripts are tested with pytest. Install Python dependencies for
running those tests:
```bash
$ pip install -r requirements.txt
```

Run the test suite with pytest:

```bash
$ pytest
```

Note that this will interact with your real system clipboard, so make sure you
don't have anything in there you want to keep when running tests!

## Building and Installing

To build both apps and install to `/Applications/`:

```bash
$ make install
```

The build process:
1. Compiles the Swift binary (`bin/html-clipboard`)
2. Converts PNG icons to ICNS format
3. Uses [Platypus](https://sveinbjorn.org/platypus) command-line tool to package
   the bash scripts as Mac apps

See `Makefile` and `build-apps.sh` for the full configuration.

## Distribution (Maintainer Only)

To build, zip, and upload the apps for distribution:

```bash
$ make distribute
```

This creates the zip files referenced in the installation instructions above and
uploads them to the server. This target is specific to the maintainer's setup.

## Publishing to the Mac App Store

`make app-store` builds a signed installer package for App Store Connect. It
needs, one time:

1. An Apple Developer Program membership.
2. An App ID for `com.jefftk.ClipboardMarkdown` in the developer portal.
3. "Apple Distribution" and "Mac Installer Distribution" certificates in your
   keychain (`security find-identity -v` lists what you have).
4. A Mac App Store provisioning profile for that App ID.
5. An app record in App Store Connect using the same bundle identifier.

Then:

```bash
$ SIGN_IDENTITY="Apple Distribution: Your Name (TEAMID)" \
  INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Your Name (TEAMID)" \
  PROVISIONING_PROFILE=~/Downloads/Clipboard_Markdown.provisionprofile \
  BUILD_VERSION=2 \
  make app-store
```

`BUILD_VERSION` has to increase with every upload. Upload the resulting
`ClipboardMarkdown.pkg` with Transporter.app or `xcrun altool --upload-app`.

Note that the Pandoc-based apps cannot go to the App Store: a sandboxed app
cannot run a binary from `/opt/homebrew`, and Pandoc is GPL-licensed, which is
incompatible with the App Store's terms.
