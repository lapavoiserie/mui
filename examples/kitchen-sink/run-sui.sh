#!/bin/bash
set -e

PLATFORM="${1:-macos}"
APP_NAME="KitchenSink"
BUNDLE_ID="com.mui.kitchensink"

echo "==> [1/4] Compiling Haxe (generates C++ & Swift)..."
haxe build-sui.hxml

echo "==> [2/4] Assembling Xcode project..."
mkdir -p build/$PLATFORM/Sources
cp build/swift/*.swift build/$PLATFORM/Sources/

# The dynamic renderer needs the C bridge (`viewnode_*`), which a standalone
# macOS build has no source for. This app does not use it: its screen is the
# transpiled `ContentView`, which is the whole point of the transpiled path.
rm -f build/$PLATFORM/Sources/DynamicView.swift build/$PLATFORM/Sources/ViewBridge.swift

# A picture of the TRANSPILED screen, for a check that has no eyes.
#
# `sui`'s own `SUI_FRAME_DUMP` renders the DYNAMIC tree -- it photographs
# `DynamicView(node: viewnode_get_root())` -- so it says nothing about the
# `ContentView` a transpiled app actually shows. This draws that one, with
# SwiftUI's own `ImageRenderer`, and writes it without opening a window:
# nobody's screen is taken over for a test, which is the same rule the
# emulator check follows.
if [ -n "${KS_DUMP:-}" ]; then
cat > build/$PLATFORM/Sources/App.swift << 'SWIFT'
import SwiftUI
import AppKit

@main
struct KitchenSinkApp: App {
    init() {
        HaxeRuntime.initialize()
        let path = ProcessInfo.processInfo.environment["KS_DUMP"]!
        let renderer = ImageRenderer(content: ContentView().frame(width: 900, height: 1100))
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            FileHandle.standardError.write(Data("no image".utf8))
            exit(1)
        }
        try? png.write(to: URL(fileURLWithPath: path))
        exit(0)
    }

    var body: some Scene { WindowGroup("KitchenSink") { ContentView() } }
}
SWIFT
fi

# Runtime stubs (standalone mode, no C++ bridge yet)
if [ ! -f build/$PLATFORM/Sources/HaxeRuntime.swift ]; then
cat > build/$PLATFORM/Sources/HaxeRuntime.swift << 'SWIFT'
import Foundation
public final class HaxeRuntime {
    public static func initialize() {
        print("[HaxeRuntime] Initialized (standalone mode)")
    }
}
SWIFT
fi

if [ ! -f build/$PLATFORM/Sources/HaxeBridge.swift ]; then
cat > build/$PLATFORM/Sources/HaxeBridge.swift << 'SWIFT'
import Foundation
import Observation
@Observable
public final class HaxeBridge {
    public static let shared = HaxeBridge()
    private var actions: [String: () -> Void] = [:]
    private init() {}
    public func invokeAction(_ name: String) {
        if let action = actions[name] { action() }
    }
}
SWIFT
fi

cat > build/$PLATFORM/project.yml << YAML
name: $APP_NAME
options:
  bundleIdPrefix: com.sui
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "15.0"
settings:
  SWIFT_VERSION: "5.9"
targets:
  $APP_NAME:
    type: application
    platform: macOS
    sources:
      - path: Sources
        type: group
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID
      GENERATE_INFOPLIST_FILE: true
YAML

cd build/$PLATFORM
xcodegen generate 2>&1 | grep -v "^$"
cd ../..

echo "==> [3/4] Building with Xcode..."
cd build/$PLATFORM
xcodebuild build \
  -project $APP_NAME.xcodeproj \
  -scheme $APP_NAME \
  -configuration Debug \
  -derivedDataPath ./DerivedData \
  -quiet

echo "==> [4/4] Launching..."
echo "app: $(pwd)/DerivedData/Build/Products/Debug/$APP_NAME.app"/Build/Products/Debug/$APP_NAME.app
