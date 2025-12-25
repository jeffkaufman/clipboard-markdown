import pytest
import subprocess
from pathlib import Path
from AppKit import NSPasteboard


def run_script(script_name, input_text=None):
    """Run a script from the bin directory."""
    script_path = Path(__file__).parent / "bin" / script_name
    if input_text is not None:
        result = subprocess.run(
            [str(script_path)],
            input=input_text,
            capture_output=True,
            text=True
        )
    else:
        result = subprocess.run(
            [str(script_path)],
            capture_output=True,
            text=True
        )
    return result


def put_html_on_clipboard(html):
    pasteboard = NSPasteboard.generalPasteboard()
    pasteboard.clearContents()
    pasteboard.setString_forType_(html, "public.html")


def get_html_from_clipboard():
    return NSPasteboard.generalPasteboard().stringForType_("public.html")


@pytest.fixture
def example_full_html():
    with open("examples/example.html") as inf:
        return inf.read()


@pytest.fixture
def example_markdown():
    with open("examples/example.md") as inf:
        return inf.read()


@pytest.fixture
def example_normalized():
    with open("examples/example_normalized.html") as inf:
        return inf.read()


def test_html_clipboard_get(example_full_html):
    """Test html-clipboard get."""
    put_html_on_clipboard(example_full_html)
    bin_dir = Path(__file__).parent / "bin"
    html_clipboard = bin_dir / "html-clipboard"
    result = subprocess.run(
        [str(html_clipboard), "get"],
        capture_output=True,
        text=True
    )
    assert result.returncode == 0, f"html-clipboard get failed: {result.stderr}"
    assert result.stdout == example_full_html, \
        "html-clipboard get output doesn't match clipboard contents"


def test_html_clipboard_set(example_full_html):
    """Test html-clipboard set."""
    bin_dir = Path(__file__).parent / "bin"
    html_clipboard = bin_dir / "html-clipboard"
    result = subprocess.run(
        [str(html_clipboard), "set"],
        input=example_full_html,
        capture_output=True,
        text=True
    )
    assert result.returncode == 0, f"html-clipboard set failed: {result.stderr}"
    assert get_html_from_clipboard() == example_full_html, \
        "html-clipboard set didn't put correct HTML on clipboard"


def test_markdownify_clipboard(example_full_html, example_markdown):
    """Test markdownify-clipboard."""
    put_html_on_clipboard(example_full_html)
    result = run_script("markdownify-clipboard")
    assert result.returncode == 0, \
        f"markdownify-clipboard failed: {result.stderr}"
    assert subprocess.run(['pbpaste'], capture_output=True, text=True).stdout \
        == example_markdown, \
        "markdownify-clipboard output doesn't match expected markdown"


def test_normalize_clipboard(example_full_html, example_normalized):
    """Test normalize-clipboard."""
    put_html_on_clipboard(example_full_html)
    result = run_script("normalize-clipboard")
    assert result.returncode == 0, f"normalize-clipboard failed: {result.stderr}"
    assert get_html_from_clipboard() == example_normalized, \
        "normalize-clipboard output doesn't match expected HTML"
