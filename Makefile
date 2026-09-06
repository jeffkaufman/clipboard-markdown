all: bin/html-clipboard logos/clipboard-md.icns logos/clipboard-n.icns

apps: all bin/markdownify-clipboard bin/normalize-clipboard
	./build-apps.sh

install: apps
	./install-apps.sh

# The native menu bar app in macapp/.  Unlike the Platypus apps above it has no
# pandoc dependency, runs in the App Sandbox, and can go to the Mac App Store.
app:
	./build-app.sh

app-install: app
	killall "Clipboard Markdown" 2>/dev/null || true
	rm -rf "/Applications/Clipboard Markdown.app"
	cp -r "Clipboard Markdown.app" /Applications/
	open "/Applications/Clipboard Markdown.app"

# A local development build.  It uses its own bundle identifier, so macOS keeps
# it entirely separate from the release app: separate sandbox container,
# separate login item, no LaunchServices confusion.  Both can run at once, and
# the "N" icon tells them apart in the menu bar.
DEV_NAME = Clipboard Normalizer (Dev)
DEV_BUNDLE_ID = com.jefftk.ClipboardMarkdown.dev

dev:
	APP_NAME="$(DEV_NAME)" \
	BUNDLE_ID="$(DEV_BUNDLE_ID)" \
	ICON="$(CURDIR)/logos/clipboard-n.png" \
	  ./build-app.sh

dev-install: dev
	killall "$(DEV_NAME)" 2>/dev/null || true
	rm -rf "/Applications/$(DEV_NAME).app"
	cp -r "$(DEV_NAME).app" /Applications/
	open "/Applications/$(DEV_NAME).app"
	@echo ""
	@echo "Installed and launched /Applications/$(DEV_NAME).app"

# Signed installer package for App Store Connect.  See package-app-store.sh for
# the certificates and profile it needs.
app-store:
	./package-app-store.sh

app-test:
	swift test --package-path macapp

# Note: This target is specific to jefftk's setup and won't work for others
distribute: apps
	@echo "Creating zip files..."
	zip -r markdownify-clipboard-app.zip "Markdownify Clipboard.app"
	zip -r normalize-clipboard-app.zip "Normalize Clipboard.app"
	@echo "Uploading to server..."
	scp markdownify-clipboard-app.zip normalize-clipboard-app.zip ps:jtk/
	@echo "Distribution complete!"

bin/html-clipboard: src/html-clipboard.swift
	swiftc src/html-clipboard.swift -o bin/html-clipboard

logos/clipboard-md.icns: logos/clipboard-md.png
	mkdir -p logos/clipboard-md.iconset
	@for size in 16 32 128 256 512; do \
		sips -z $$size $$size logos/clipboard-md.png --out logos/clipboard-md.iconset/icon_$${size}x$${size}.png; \
		double=$$((size * 2)); \
		sips -z $$double $$double logos/clipboard-md.png --out logos/clipboard-md.iconset/icon_$${size}x$${size}@2x.png; \
	done
	iconutil -c icns logos/clipboard-md.iconset -o logos/clipboard-md.icns

logos/clipboard-n.icns: logos/clipboard-n.png
	mkdir -p logos/clipboard-n.iconset
	@for size in 16 32 128 256 512; do \
		sips -z $$size $$size logos/clipboard-n.png --out logos/clipboard-n.iconset/icon_$${size}x$${size}.png; \
		double=$$((size * 2)); \
		sips -z $$double $$double logos/clipboard-n.png --out logos/clipboard-n.iconset/icon_$${size}x$${size}@2x.png; \
	done
	iconutil -c icns logos/clipboard-n.iconset -o logos/clipboard-n.icns

clean:
	rm -f bin/html-clipboard
	rm -f logos/*.icns
	rm -rf logos/*.iconset
	rm -rf "Markdownify Clipboard.app"
	rm -rf "Normalize Clipboard.app"
	rm -rf "Clipboard Markdown.app"
	rm -rf "$(DEV_NAME).app"
	rm -f ClipboardMarkdown.pkg
	rm -rf macapp/.build

.PHONY: all apps install distribute clean app app-install app-store app-test dev dev-install
