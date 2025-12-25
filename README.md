# Clipboard Markdown

Mac utilities for interacting with the system clipboard as HTML and Markdown.

## Overview

This toolkit provides utilities for working with clipboard content:

- **markdownify-clipboard** - Convert HTML on clipboard to Markdown text
- **normalize-clipboard** - Normalize HTML formatting on clipboard by
  round-tripping through Markdown
- **html-clipboard** - Low-level utility to get/set HTML on the clipboard

## Quick Start - Pre-built Apps

The easiest way to use these tools is to download the pre-built Mac apps:

- [Normalize Clipboard.app](https://www.jefftk.com/normalize-clipboard-app.zip)
- [Markdownify Clipboard.app](https://www.jefftk.com/markdownify-clipboard-app.zip)

### Installation Steps:

1. Install Pandoc.  If you use Homebrew this is just:

   ```bash
   brew install pandoc
   ```

   Otherwise:

   a. Go to https://pandoc.org/installing.html

   b. Click "Download the latest installer"

   c. Download the file named `pandoc-...-arm64-macOS.pkg` (for Apple Silicon
      Macs) or `pandoc-...-x86_64-macOS.pkg` (for Intel Macs)

   d. Open the downloaded `.pkg` file and follow the installation wizard

2. **Download** one or both apps from the links above

3. **Extract** the `.zip` file by double-clicking it

4. **Move to Applications folder:**
   - Drag the `.app` file to your `/Applications` folder

5. **Open the app for the first time:**
   - Double-click the app in your Applications folder
   - macOS will likely show a warning that the app "cannot be opened because it
     is from an unidentified developer"
   - Click "OK" to dismiss the warning

6. **Approve the app to run:**
   - Open **System Settings**
   - Go to **Privacy & Security**
   - Scroll down to find a message about the app being blocked
   - Click **Open Anyway**
   - Click **Open** in the confirmation dialog

7. **Add to startup (optional but recommended):**
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
markdownify-clipboard
```

**Example:**
1. Copy formatted text from a web page
2. Run `markdownify-clipboard`
3. Paste.  You'll get plain Markdown text

### normalize-clipboard

Normalizes HTML formatting by converting clipboard HTML to Markdown and back to
HTML, removing unnecessary formatting.

```bash
normalize-clipboard
```

**Example:**
1. Copy formatted HTML from a document
2. Run `normalize-clipboard`
3. Paste.  The HTML will be cleaner and simplified

### html-clipboard

Low-level utility for getting and setting HTML on the clipboard.

```bash
html-clipboard get        # Print HTML from clipboard to stdout
html-clipboard set        # Read HTML from stdin and put on clipboard
```

**Example:**
```bash
html-clipboard get > saved.html                # Get HTML from clipboard
echo "<h1>Title</h1>" | html-clipboard set     # Put HTML on clipboard
```

## Adding to PATH

To run these scripts from anywhere, add the bin directory to your PATH. For
example, add to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$PATH:/path/to/clipboard-markdown/bin"
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

