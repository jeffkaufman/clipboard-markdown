// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipboardMarkdown",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ClipboardKit", targets: ["ClipboardKit"]),
        .executable(name: "ClipboardMarkdown", targets: ["ClipboardMarkdown"]),
    ],
    dependencies: [
        // MIT.  A real HTML5 parser, so we cope with the tag soup that
        // browsers and word processors put on the clipboard.
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
        // Apache-2.0, wraps swift-cmark (BSD-2).  Markdown -> HTML.
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "ClipboardKit",
            dependencies: [
                "SwiftSoup",
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .executableTarget(name: "ClipboardMarkdown", dependencies: ["ClipboardKit"]),
        .testTarget(name: "ClipboardKitTests", dependencies: ["ClipboardKit"]),
    ]
)
