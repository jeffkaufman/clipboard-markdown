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

Install Python dependencies for running tests:
```bash
$ pip install -r requirements.txt
```

Run the test suite with pytest:

```bash
$ pytest
```

Note that this will interact with your real system clipboard, so make sure you
don't have anything in there you want to keep when running tests!

## Releasing

Compatible with Platypus packaging.  Two different "apps", made almost the same
way: "Normalize Clipboard" and "Markdownify Clipboard".  Settings:

App Name: "Normalize Clipboard" or "Markdownify Clipboard"
Script Type: bash
Script Path: /path/to/clipboard-markdown/bin/{command}
Interface: Status Menu
Status Item Settings
   Status Item: Icon
   Icon: logos/clipboard-n.png or logos/clipboard-md.png
Custom Icon: logos/clipboard-n.png or logos/clipboard-md.png
Identifier: com.jefftk.NormalizeClipboard or com.jefftk.MarkdownifyClipboard
Author: Jeff Kaufman
Run in background: false
Version: 1.0
Bundled Files: build and add html-clipboard

![Platypus Markdownify Clipboard Settings](platypus-markdownify-clipboard-settings.png)

