#!/bin/bash
# Build the iOS probe for the simulator, wrap it in an app bundle, install it and
# launch it.
#
# hxcpp's own iOS toolchain is not used, and cannot be: `iphonesim-toolchain.xml`
# in 4.3.2 knows only `-arch i386` and `-arch x86_64`, and every simulator on an
# Apple Silicon Mac is arm64. It also passes `-miphoneos-version-min`, which is
# the device flag, so clang refuses any deployment target above iOS 10.
#
# So Haxe generates C++ and stops, and this compiles it -- the generated sources
# plus the hxcpp runtime, the same set of runtime files the SailfishOS packaging
# builds through qmake. One toolchain fewer to argue with, and the same shape as
# the platform that already works this way.
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
HXCPP="$(haxelib libpath hxcpp)"
PUI="$(haxelib libpath pui)"
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
BUILD="$HERE/build/ios"
APP="$BUILD/KitchenSink.app"
DEVICE="${PROBE_DEVICE:-iPhone 15 Pro}"

echo "-- generating C++"
cd "$HERE"
haxe build-pui-ios.hxml

echo "-- compiling for arm64 simulator"
rm -rf "$BUILD"
mkdir -p "$BUILD/obj" "$APP"

TRIPLE="arm64-apple-ios15.0-simulator"
FLAGS=(-target "$TRIPLE" -isysroot "$SDK" -O1 -fno-strict-aliasing
	-DHX_MACOS -DIPHONE -DHXCPP_M64 -DHXCPP_ARM64 -DHXCPP_CPP11 -DHX_SMART_STRINGS
	# The collector scans the registers by hand, and picks its assembly from
	# HX_MACOS plus HXCPP_M64 -- which on this machine means x86-64 assembly for
	# an arm64 target. hxcpp keeps a setjmp path for exactly this case; the arm64
	# assembly path in GcRegCapture.h is commented out upstream.
	-DHXCPP_CAPTURE_SETJMP
	-DHXCPP_VISIT_ALLOCS -DHXCPP_GC_GENERATIONAL -DHXCPP_API_LEVEL=430
	-I"$HXCPP/include" -I"$PUI/src/pui/backend/ios/native" -I"$HERE/build/pui-ios/include" -I"$HERE/build/pui-ios/src"
	-std=c++11 -stdlib=libc++ -Wno-everything)

SOURCES=()
while read -r f; do SOURCES+=("$HXCPP/$f"); done <<'EOF'
src/Array.cpp
src/Dynamic.cpp
src/Enum.cpp
src/Math.cpp
src/String.cpp
src/hx/Anon.cpp
src/hx/Boot.cpp
src/hx/CFFI.cpp
src/hx/Class.cpp
src/hx/Date.cpp
src/hx/Debug.cpp
src/hx/Hash.cpp
src/hx/Interface.cpp
src/hx/Lib.cpp
src/hx/Object.cpp
src/hx/RunLibs.cpp
src/hx/StdLibs.cpp
src/hx/Thread.cpp
src/hx/gc/GcRegCapture.cpp
src/hx/gc/GcCommon.cpp
src/hx/gc/Immix.cpp
src/hx/libs/std/Process.cpp
src/hx/libs/std/Socket.cpp
src/hx/libs/std/Random.cpp
src/hx/libs/std/File.cpp
src/hx/libs/std/Sys.cpp
EOF

# Everything Haxe generated, plus the surface itself.
# `__lib__.cpp` defines `__hxcpp_lib_main` for a program embedded in a host, and
# `__main__.cpp` defines `main` plus the same entry point for a standalone one.
# Taking both gives duplicate symbols -- the trap the SailfishOS packaging hit
# from the other side.
while IFS= read -r f; do SOURCES+=("$f"); done < <(find "$HERE/build/pui-ios/src" -name '*.cpp' ! -name '__lib__.cpp')
SOURCES+=("$PUI/src/pui/backend/ios/native/pui_ios.mm")

n=0
for s in "${SOURCES[@]}"; do
	n=$((n + 1))
	xcrun clang++ "${FLAGS[@]}" -c "$s" -o "$BUILD/obj/$n.o" &
	# A dozen at a time: enough to use the machine, few enough not to swamp it.
	if [ $((n % 12)) -eq 0 ]; then wait; fi
done
wait

echo "-- linking"
xcrun clang++ -target "$TRIPLE" -isysroot "$SDK" "$BUILD"/obj/*.o \
	-framework UIKit -framework CoreText -framework CoreGraphics \
	-framework Foundation -framework QuartzCore \
	-stdlib=libc++ -o "$APP/KitchenSink"

cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>KitchenSink</string>
	<key>CFBundleIdentifier</key><string>com.lapavoiserie.pui.kitchensink</string>
	<key>CFBundleName</key><string>Kitchen Sink</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>1.0</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>LSRequiresIPhoneOS</key><true/>
	<key>MinimumOSVersion</key><string>15.0</string>
	<key>UIDeviceFamily</key><array><integer>1</integer></array>
	<key>UILaunchScreen</key><dict/>
	<key>UISupportedInterfaceOrientations</key>
	<array><string>UIInterfaceOrientationPortrait</string></array>
</dict>
</plist>
PLIST

echo "-- installing on $DEVICE"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null 2>&1 || true
xcrun simctl install "$DEVICE" "$APP"
xcrun simctl launch "$DEVICE" com.lapavoiserie.pui.kitchensink

echo
echo "container: $(xcrun simctl get_app_container "$DEVICE" com.lapavoiserie.pui.kitchensink data)"
echo "screenshot: xcrun simctl io '$DEVICE' screenshot shot.png"
