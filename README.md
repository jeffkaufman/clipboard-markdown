# Clipboard Markdown

Mac utilities for interacting with the system clipboard as HTML and Markdown.

## Overview

This toolkit provides utilities for working with clipboard content:

- **markdownify-clipboard** - Convert HTML on clipboard to Markdown text
- **normalize-clipboard** - Normalize HTML formatting on clipboard by
  round-tripping through Markdown
- **html-clipboard** - Low-level utility to get/set HTML on the clipboard

## Requirements

- macOS
- [Pandoc](https://pandoc.org/)
- Xcode Command Line Tools (for building the Swift binary)

## Installation

1. Install Pandoc:
   ```bash
   brew install pandoc
   ```

2. Build the html-clipboard binary:
   ```bash
   make
   ```

3. Install Python dependencies (for testing):
   ```bash
   pip install -r requirements.txt
   ```

## Usage

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
html-clipboard get | pandoc -f html -t gfm-raw_html  # HTML to Markdown
echo "<h1>Title</h1>" | html-clipboard set           # Put HTML on clipboard
```

## Platypus App Bundle

This project is designed to be packaged with [Platypus](https://sveinbjorn.org/platypus)
as a Mac application. When bundled, the scripts will automatically use resources
from `$resourcePath` if available, allowing you to bundle `pandoc` and other
dependencies with the app.

## Adding to PATH

To run these scripts from anywhere, add the bin directory to your PATH. For
example, add to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$PATH:/path/to/clipboard-markdown/bin"
```

## Testing

Run the test suite with pytest:

```bash
pytest
```

Note that this will interact with your real system clipboard, so make sure you
don't have anything in there you want to keep when running tests!
