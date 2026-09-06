import AppKit
import ClipboardKit

enum ClipboardError: LocalizedError {
    case noRichText
    case noPlainText
    case timedOut

    var errorDescription: String? {
        switch self {
        case .noRichText:
            return "No formatted text on the clipboard."
        case .noPlainText:
            return "No text on the clipboard."
        case .timedOut:
            return "That took too long, so nothing was changed."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noRichText:
            return "Copy some formatted text — from a web page or a document — and try again."
        case .noPlainText:
            return "Copy some Markdown text and try again."
        case .timedOut:
            return "The clipboard held an unusually complicated document."
        }
    }
}

enum ClipboardService {

    /// Deeply nested HTML makes the parser slow enough to notice — pathological
    /// input can take a minute — so conversions run off the main thread and the
    /// menu stays usable.  There is no way to cancel a parse already underway,
    /// so on timeout we stop waiting and leave the clipboard alone.
    private static let timeout: TimeInterval = 10

    /// Whether the result or the timeout got there first.  Only ever touched on
    /// the main queue, which serializes the two.
    private final class Outcome {
        var settled = false
    }

    /// Runs a conversion in place on the clipboard.  Success is silent, which
    /// is the point of the app; failure says why.
    static func run(_ conversion: Conversion) {
        let input: String
        do {
            input = try read(for: conversion)
        } catch {
            presentError(error, during: conversion)
            return
        }

        // If the clipboard moves on while we are working, the result is about
        // something the user has already replaced, so drop it.
        let changeCount = Pasteboard.changeCount
        let outcome = Outcome()

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try transform(input, with: conversion) }
            DispatchQueue.main.async {
                guard !outcome.settled else { return }
                outcome.settled = true
                guard Pasteboard.changeCount == changeCount else { return }

                switch result {
                case .success(let output):
                    write(output, for: conversion)
                case .failure(let error):
                    presentError(error, during: conversion)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !outcome.settled else { return }
            outcome.settled = true
            presentError(ClipboardError.timedOut, during: conversion)
        }
    }

    private static func read(for conversion: Conversion) throws -> String {
        switch conversion {
        case .normalize, .markdownify:
            guard let html = Pasteboard.readHTML() else { throw ClipboardError.noRichText }
            return html
        case .htmlify:
            guard let text = Pasteboard.readPlainText(),
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { throw ClipboardError.noPlainText }
            return text
        }
    }

    private static func transform(_ input: String, with conversion: Conversion) throws -> String {
        switch conversion {
        case .normalize: return try ClipboardConversions.normalize(html: input)
        case .markdownify: return try ClipboardConversions.markdownify(html: input)
        case .htmlify: return try ClipboardConversions.htmlify(markdown: input)
        }
    }

    private static func write(_ output: String, for conversion: Conversion) {
        switch conversion {
        case .normalize, .htmlify: Pasteboard.writeHTML(output)
        case .markdownify: Pasteboard.writePlainText(output)
        }
    }

    static func presentError(_ error: Error, during conversion: Conversion) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = (error as? LocalizedError)?.errorDescription
            ?? "\(conversion.title) failed."
        alert.informativeText = (error as? LocalizedError)?.recoverySuggestion
            ?? error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
