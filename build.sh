#!/bin/bash
set -e

APP_NAME="LyricFetcher"
APP_BUNDLE="$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

# Clean previous build
rm -rf "$APP_BUNDLE"

# Create bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy icon
cp Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"

# Write PkgInfo (tells macOS this is an application)
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Write Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.lyricfetcher.app</string>
    <key>CFBundleName</key>
    <string>Lyric Fetcher</string>
    <key>CFBundleDisplayName</key>
    <string>Lyric Fetcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.music</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
</dict>
</plist>
EOF

echo "Compiling Swift files..."
swiftc \
    -parse-as-library \
    -target arm64-apple-macosx13.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    Sources/*.swift \
    -o "$MACOS_DIR/$APP_NAME"

# Ad-hoc sign the app so macOS trusts it as a GUI app
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Built $APP_BUNDLE successfully."
