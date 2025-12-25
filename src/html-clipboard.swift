import Cocoa

let args = CommandLine.arguments

if args.count < 2 {
    print("Usage: html-clipboard [get|set]")
    exit(1)
}

let board = NSPasteboard.general

if args[1] == "get" {
    // Read HTML from clipboard and print to stdout
    if let html = board.string(forType: .html) {
        print(html, terminator: "")
    }
} else if args[1] == "set" {
    // Read from stdin and write to clipboard as HTML
    let data = FileHandle.standardInput.readDataToEndOfFile()
    if let str = String(data: data, encoding: .utf8) {
        board.clearContents()
        board.setString(str, forType: .html)
        // Also set plain text version so it pastes nicely in code editors
        board.setString(str, forType: .string) 
    }
}
